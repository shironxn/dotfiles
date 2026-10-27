#!/usr/bin/env python3
"""Wallpaper picker — GTK3, two-pane with live preview.

Reads absolute image paths on stdin (one per line), prints the selected path
on stdout. Cancelling prints nothing, so the caller can distinguish "user
picked one" from "user pressed Escape".

Preview and thumbnails are loaded off the UI thread; results are committed
through GLib.idle_add and discarded when the selection has moved on, so
holding Down does not queue up a backlog of stale decodes.
"""

import hashlib
import json
import os
import subprocess
import sys
import threading
from concurrent.futures import ThreadPoolExecutor

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("GdkPixbuf", "2.0")
from gi.repository import Gdk, GdkPixbuf, GLib, Gtk, Pango  # noqa: E402

GLib.set_prgname("wallpaper-picker")
GLib.set_application_name("Wallpaper Picker")

CACHE_DIR = os.path.join(GLib.get_user_cache_dir(), "wallpaper-picker")
THUMB_SIZE = 96
PREVIEW_W, PREVIEW_H = 720, 405
DEBOUNCE_MS = 90
IMAGE_EXTS = (".jpg", ".jpeg", ".png", ".webp")
WANT_W, WANT_H = 1180, 760
LIST_W = 400
THUMB_WORKERS = 6
WAL_JSON = os.path.join(GLib.get_user_cache_dir(), "wal", "colors.json")


def wal_palette():
    """pywal colours, mapped exactly like templates/colors-fuzzel.ini does.

    Without this the picker is the one window on the desktop that ignores the
    palette: every other menu recolours when the wallpaper changes.
    """
    try:
        with open(WAL_JSON) as handle:
            wal = json.load(handle)
        special, colors = wal["special"], wal["colors"]
        return {
            "bg": special["background"],
            "fg": special["foreground"],
            "match": colors["color4"],
            "sel": colors["color8"],
        }
    except (OSError, ValueError, KeyError) as exc:
        print(f"[wallpaper-picker] pywal palette unavailable ({exc}); "
              "falling back to the GTK theme", file=sys.stderr)
        return None


def apply_wal_theme():
    pal = wal_palette()
    if pal is None:
        return
    css = f"""
    window.picker, window.picker box, window.picker paned,
    window.picker scrolledwindow, window.picker viewport,
    window.picker listbox, window.picker list {{ background-color: {pal['bg']}; }}
    window.picker {{ color: {pal['fg']}; }}
    window.picker entry {{
        background-color: {pal['bg']};
        color: {pal['fg']};
        border-bottom: 1px solid {pal['match']};
        padding: 9px 12px;
        font: 13px monospace;
    }}
    window.picker row {{
        background-color: transparent;
        color: {pal['fg']};
        border-radius: 8px;
        margin: 1px 8px;
        padding: 2px 4px;
    }}
    window.picker row:hover {{ background-color: alpha({pal['sel']}, 0.45); }}
    window.picker row:selected {{ background-color: {pal['sel']}; color: {pal['fg']}; }}
    window.picker label {{ color: {pal['fg']}; }}
    window.picker label.subtle {{ color: {pal['match']}; font-size: 0.9em; }}
    window.picker image {{ background-color: transparent; }}
    window.picker scrollbar, window.picker scrollbar trough {{
        background-color: {pal['bg']};
        border: none;
    }}
    window.picker scrollbar slider {{
        background-color: {pal['match']};
        border-radius: 6px;
        min-width: 8px;
        min-height: 8px;
        border: none;
    }}
    window.picker scrollbar slider:hover {{ background-color: {pal['sel']}; }}
    """
    provider = Gtk.CssProvider()
    try:
        provider.load_from_data(css.encode())
    except Exception as exc:
        print(f"[wallpaper-picker] CSS rejected ({exc})", file=sys.stderr)
        return
    screen = Gdk.Screen.get_default()
    if screen is None:
        return
    # PRIORITY_APPLICATION (600) loses to the GTK theme provider (800), so
    # adw-gtk3 keeps winning the window background. USER is the same numeric
    # priority as THEME but is added later, which wins ties.
    Gtk.StyleContext.add_provider_for_screen(
        screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_USER)

_render_locks = {}


def cache_file(path, variant):
    """Cache path keyed on path+mtime so an edited image is re-rendered."""
    try:
        stamp = os.path.getmtime(path)
    except OSError:
        stamp = 0
    key = hashlib.md5(f"{path}:{stamp}:{variant}".encode()).hexdigest()
    return os.path.join(CACHE_DIR, f"{key}.jpg")


def _render(src, out, geometry):
    """Shell out to ImageMagick. Safe off-thread; GdkPixbuf is not."""
    lock = _render_locks.setdefault(src, threading.Lock())
    with lock:
        if os.path.exists(out):
            return out
        os.makedirs(CACHE_DIR, exist_ok=True)
        tmp = f"{out}.{os.getpid()}.{threading.get_ident()}.tmp"
        try:
            subprocess.run(
                ["magick", src, "-auto-orient", *geometry, "-quality", "88", tmp],
                check=True, capture_output=True, timeout=20)
            os.replace(tmp, out)
        except (subprocess.SubprocessError, OSError) as exc:
            for leftover in (tmp, out):
                try:
                    os.unlink(leftover)
                except OSError:
                    pass
            print(f"[wallpaper-picker] render failed for {src}: {exc}",
                  file=sys.stderr)
            return None
    return out


def make_thumb(path, size=THUMB_SIZE):
    return _render(path, cache_file(path, f"thumb{size}"),
                   ["-resize", f"{size}x{size}^", "-gravity", "center",
                    "-extent", f"{size}x{size}"])


def make_preview(path, width, height):
    return _render(path, cache_file(path, f"prev{width}x{height}"),
                   ["-resize", f"{width}x{height}>"])


def load_small(path, width, height):
    return GdkPixbuf.Pixbuf.new_from_file_at_scale(path, width, height, True)


def describe(path):
    try:
        mib = os.stat(path).st_size / (1024 * 1024)
    except OSError:
        return ""
    try:
        px = GdkPixbuf.Pixbuf.new_from_file(path)
        return f"{px.get_width()}x{px.get_height()}  ·  {mib:.1f} MiB"
    except Exception as exc:
        print(f"[wallpaper-picker] describe failed for {path}: {exc}",
              file=sys.stderr)
        return f"{mib:.1f} MiB"


class Picker:
    def __init__(self, paths):
        self.paths = paths
        self.rows = {}          # path -> Gtk.ListBoxRow
        self.pending = None     # path whose preview is queued
        self.generation = 0     # bumped on every selection change
        self.selected = None

        self.window = Gtk.Window(title="Wallpaper")
        self.window.set_position(Gtk.WindowPosition.CENTER)
        self.window.set_type_hint(Gdk.WindowTypeHint.DIALOG)
        self.window.get_style_context().add_class("picker")
        apply_wal_theme()
        want_w, want_h = self.fit_to_monitor()
        self.window.set_default_size(want_w, want_h)
        # Lower bound only. Note the height still comes out as the full
        # workarea height under sway even for a one-label window, so this is
        # not a reliable way to force an exact height -- the picker just
        # takes what it is given.
        self.window.set_size_request(want_w, want_h)
        self.window.connect("destroy", Gtk.main_quit)
        self.window.connect("key-press-event", self.on_key)

        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.window.add(outer)

        search = Gtk.SearchEntry()
        search.set_placeholder_text("Filter wallpaper…")
        search.connect("search-changed", self.on_search)
        outer.pack_start(search, False, False, 0)
        self.search = search

        split = Gtk.Paned(orientation=Gtk.Orientation.HORIZONTAL)
        split.set_position(400)
        outer.pack_start(split, True, True, 0)

        self.listbox = Gtk.ListBox()
        self.listbox.set_selection_mode(Gtk.SelectionMode.SINGLE)
        self.listbox.connect("row-selected", self.on_row_selected)
        scroller = Gtk.ScrolledWindow()
        scroller.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        # Without this the list's 220 rows inflate the toplevel and the
        # preview pane collapses to a few pixels tall.
        scroller.set_propagate_natural_width(False)
        scroller.set_propagate_natural_height(False)
        scroller.set_size_request(LIST_W, 420)
        scroller.add(self.listbox)
        split.pack1(scroller, True, False)

        right = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        right.set_border_width(14)
        self.image = Gtk.Image()
        self.image.set_valign(Gtk.Align.CENTER)
        self.image.set_vexpand(True)
        right.pack_start(self.image, True, True, 0)

        self.caption = Gtk.Label()
        self.caption.set_ellipsize(Pango.EllipsizeMode.MIDDLE)
        self.caption.set_justify(Gtk.Justification.CENTER)
        self.caption.get_style_context().add_class("subtle")
        right.pack_start(self.caption, False, False, 0)

        # Paned.pack2 replaces whatever already sits in that pane, so the
        # placeholder has to live inside the same box and toggle visibility.
        self.empty = Gtk.Label(label="No match")
        right.pack_start(self.empty, True, True, 0)
        split.pack2(right, True, False)
        split.set_position(LIST_W)
        right.set_size_request(360, -1)

        # Preview gets its own single-thread executor: it is the interaction
        # the user is waiting on, so it must never queue behind the 220
        # thumbnail jobs.
        self.pool = ThreadPoolExecutor(max_workers=THUMB_WORKERS)
        self.preview_pool = ThreadPoolExecutor(max_workers=1)
        self.build_rows()
        self.window.show_all()
        self.empty.hide()
        if self.paths:
            self.listbox.select_row(self.listbox.get_row_at_index(0))

    @staticmethod
    def fit_to_monitor():
        width, height = WANT_W, WANT_H
        try:
            display = Gdk.Display.get_default()
            monitor = display.get_primary_monitor() or display.get_monitor(0)
            if monitor is not None:
                area = monitor.get_workarea()
                width = min(width, int(area.width * 0.92))
                height = min(height, int(area.height * 0.88))
        except Exception as exc:
            print(f"[wallpaper-picker] monitor probe failed: {exc}",
                  file=sys.stderr)
        return max(width, 800), max(height, 500)

    def build_rows(self):
        for path in self.paths:
            row = Gtk.ListBoxRow()
            box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
            box.set_border_width(6)

            thumb = Gtk.Image()
            thumb.set_size_request(THUMB_SIZE // 2, THUMB_SIZE // 2)
            thumb.set_valign(Gtk.Align.CENTER)
            box.pack_start(thumb, False, False, 0)

            text = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
            text.set_valign(Gtk.Align.CENTER)
            name = Gtk.Label(label=os.path.basename(path))
            name.set_xalign(0)
            name.set_ellipsize(Pango.EllipsizeMode.MIDDLE)
            name.set_max_width_chars(28)
            text.pack_start(name, False, False, 0)

            folder = os.path.basename(os.path.dirname(path))
            sub = Gtk.Label(label=folder)
            sub.set_xalign(0)
            sub.get_style_context().add_class("subtle")
            text.pack_start(sub, False, False, 0)
            box.pack_start(text, True, True, 0)

            row.add(box)
            row._thumb = thumb
            row._name = name
            row._folder = folder
            self.listbox.add(row)
            self.rows[path] = row
        self.listbox.show_all()

        for path in self.paths:
            self.pool.submit(self.fill_thumb, path)

    def fill_thumb(self, path):
        row = self.rows.get(path)
        if row is None:
            return
        size = THUMB_SIZE // 2
        cached = make_thumb(path)
        if not cached:
            return
        try:
            pixbuf = load_small(cached, size, size)
        except Exception as exc:
            print(f"[wallpaper-picker] thumb load failed: {exc}", file=sys.stderr)
            return
        GLib.idle_add(self.apply_thumb, row, pixbuf)

    def apply_thumb(self, row, pixbuf):
        if row.get_parent() is not None:
            row._thumb.set_from_pixbuf(pixbuf)
        return False

    def on_search(self, entry):
        needle = entry.get_text().strip().lower()
        first_visible = None
        visible = 0
        for path, row in self.rows.items():
            haystack = f"{row._folder}/{row._name}".lower()
            hit = not needle or needle in haystack
            row.set_visible(hit)
            if hit:
                visible += 1
                if first_visible is None:
                    first_visible = row
        self.empty.set_visible(visible == 0)
        self.image.set_visible(visible > 0)
        self.caption.set_visible(visible > 0)
        if first_visible is not None and self.listbox.get_selected_row() is None:
            self.listbox.select_row(first_visible)

    def on_row_selected(self, listbox, row):
        if row is None:
            return
        path = next((p for p, r in self.rows.items() if r is row), None)
        if path is None:
            return
        self.selected = path
        self.generation += 1
        self.pending = path
        GLib.timeout_add(DEBOUNCE_MS, self.show_preview, path, self.generation)

    def show_preview(self, path, generation):
        if generation != self.generation or path != self.pending:
            return False
        self.pending = None
        self.preview_pool.submit(self.render_preview, path, generation)
        return False
    def render_preview(self, path, generation):
        # Only ImageMagick runs off-thread here; the GdkPixbuf load that
        # follows is back on the main thread, where GTK requires it.
        cached = make_preview(path, PREVIEW_W, PREVIEW_H)
        if not cached:
            GLib.idle_add(self.apply_preview, path, generation, None, "")
            return
        info = describe(path)
        try:
            pixbuf = load_small(cached, PREVIEW_W, PREVIEW_H)
        except Exception as exc:
            print(f"[wallpaper-picker] preview load failed: {exc}", file=sys.stderr)
            GLib.idle_add(self.apply_preview, path, generation, None, info)
            return
        GLib.idle_add(self.apply_preview, path, generation, pixbuf, info)

    def apply_preview(self, path, generation, pixbuf, info):
        if generation != self.generation or path != self.selected:
            return False
        if pixbuf is not None:
            self.image.set_from_pixbuf(pixbuf)
            self.caption.set_text(f"{os.path.basename(path)}   {info}")
        return False

    def on_key(self, _widget, event):
        keyval = event.keyval
        if keyval == Gdk.KEY_Escape:
            self.window.destroy()
            return True
        if keyval in (Gdk.KEY_Return, Gdk.KEY_KP_Enter):
            if self.selected:
                sys.stdout.write(self.selected + "\n")
                sys.stdout.flush()
            self.window.destroy()
            return True
        return False


def main():
    paths = []
    for line in sys.stdin:
        candidate = line.strip()
        if not candidate:
            continue
        if not candidate.lower().endswith(IMAGE_EXTS):
            continue
        if os.path.isfile(candidate):
            paths.append(candidate)
    paths.sort()
    if not paths:
        # Non-zero so wallpaper.sh knows to fall back to fuzzel rather than
        # treat this as "the user pressed Escape".
        sys.exit(1)

    Picker(paths)
    Gtk.main()


if __name__ == "__main__":
    main()
