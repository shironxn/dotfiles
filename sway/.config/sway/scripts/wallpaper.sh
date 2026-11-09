#!/bin/sh
# Apply a pywal palette and refresh everything that consumes it.
#   wallpaper.sh -i <image>   select a new wallpaper
#   wallpaper.sh -R           restore the last session at login
set -eu

WAL_DIR="$HOME/.cache/wal"
CONFIG="$HOME/.config"
mkdir -p "$WAL_DIR"
REQUESTS="$WAL_DIR/.requests"
APPLIED="$WAL_DIR/.applied"

restore=0
want=""
case "${1:-}" in
-R | --restore) restore=1 ;;
-i) want="${2:-}" ;;
*) want="${1:-}" ;;
esac

notify_error() {
  printf '[wallpaper] %s\n' "$1" >&2
  command -v notify-send >/dev/null 2>&1 &&
    notify-send -u critical "Wallpaper" "$1"
}

apply_theme() {
  # $1 = image path, empty to restore the cached session.
  # A stale template symlink (template deleted from the repo after stow)
  # makes wal crash on every export, so sweep it first.
  find "$HOME/.config/wal/templates" -xtype l -delete 2>/dev/null || true

  # -n: pywal must not spawn its own swaybg. sway owns the wallpaper through
  #     the `output * bg` rule, and a second swaybg races it for the screen.
  # -e: pywal must not run `swaymsg reload`. That reload re-runs
  #     autostart.conf, which calls this script again, which calls wal again.
  if [ -n "${1:-}" ]; then
    timeout 120 wal -n -e -i "$1" 2>/dev/null ||
      notify_error "pywal failed on $(basename "$1")"
  else
    timeout 120 wal -n -e -R 2>/dev/null ||
      printf '[wallpaper] no cached palette to restore\n' >&2
  fi
  [ -f "$WAL_DIR/colors" ] || return 0

  # pywal only writes into ~/.cache/wal; the target dirs are stow's job.
  # swayosd never creates its config dir, so make sure it exists.
  mkdir -p "$CONFIG/swayosd"
  for pair in \
    "colors-mako:$CONFIG/mako/config" \
    "colors-swaylock:$CONFIG/swaylock/config" \
    "colors-gtk.css:$CONFIG/gtk-3.0/gtk.css" \
    "style-swayosd.css:$CONFIG/swayosd/style.css"; do
    src="$WAL_DIR/${pair%%:*}"
    [ -f "$src" ] && ln -sf "$src" "${pair#*:}"
  done

  makoctl reload 2>/dev/null || true

  # The daemon outlives this script, so it must not inherit the lock fd: an
  # inherited fd 9 keeps the lock held forever and stalls every later click.
  killall -q -w swayosd-server 2>/dev/null || true
  nohup swayosd-server --style "$CONFIG/swayosd/style.css" >/dev/null 2>&1 9>&- &

  if [ -f "$WAL_DIR/wal" ]; then
    wallpaper=$(cat "$WAL_DIR/wal")
    ln -sf "$wallpaper" "$WAL_DIR/bg"
    swaymsg output '*' bg "$WAL_DIR/bg" fill >/dev/null 2>&1 || true

    # Lock screen blur, detached because it costs ~1s. Patch swaylock's config
    # only once the render exists, so a failure cannot leave a dangling image=.
    res=$(swaymsg -t get_outputs 2>/dev/null | jq -r '
      [.[] | select(.active) | .rect] | max_by(.width * .height) | "\(.width)x\(.height)"
    ' 2>/dev/null || true)
    (
      if magick "$wallpaper" -scale "${res:-1920x1080}^" -gravity center \
        -extent "${res:-1920x1080}" -scale 25% -blur 0x3 -scale 400% \
        -fill black -colorize 40% "$WAL_DIR/bg-lock.jpg" 2>/dev/null &&
        [ -s "$WAL_DIR/bg-lock.jpg" ] && [ -f "$WAL_DIR/colors-swaylock" ]; then
        sed -i '\|^image=|d' "$WAL_DIR/colors-swaylock"
        printf 'image=%s\n' "$WAL_DIR/bg-lock.jpg" >>"$WAL_DIR/colors-swaylock"
      fi
    ) 9>&- &
  fi

  # Border and bar colours over IPC. `swaymsg reload` would re-run
  # autostart.conf and cost ~1.7s; these round-trips cost ~15ms combined.
  if [ -f "$WAL_DIR/colors-sway" ]; then
    while read -r key value; do
      case "$key" in
      color0 | color1 | color2 | color4 | color6 | color7 | color8 | foreground) export "$key=$value" ;;
      esac
    done <<EOF
$(sed -n 's/^set \$\([a-z0-9]*\) \(#[0-9a-fA-F]*\)$/\1 \2/p' "$WAL_DIR/colors-sway")
EOF
    swaymsg "client.focused ${color4:-#666666} ${color4:-#666666} ${foreground:-#ffffff} ${color4:-#666666} ${color6:-#999999}; \
client.focused_inactive ${color8:-#333333} ${color8:-#333333} ${foreground:-#ffffff} ${color8:-#333333} ${color8:-#333333}; \
client.unfocused ${color0:-#222222} ${color0:-#222222} ${foreground:-#ffffff} ${color0:-#222222} ${color0:-#222222}; \
client.urgent ${color1:-#ff0000} ${color1:-#ff0000} ${foreground:-#ffffff} ${color1:-#ff0000} ${color1:-#ff0000}" >/dev/null 2>&1 || true

    # The bar reads its palette from bar.conf, which is only re-parsed on
    # reload. Push the same values directly instead. One bar is assumed;
    # get_bar_config returns its id as a bare string.
    bar_id=$(swaymsg -t get_bar_config 2>/dev/null | jq -r 'if type == "array" then .[0] else . end' 2>/dev/null || true)
    case "$bar_id" in
    "" | null) ;; # no bar configured
    *)
      swaymsg "bar $bar_id colors background ${color0:-#222222}; \
bar $bar_id colors statusline ${foreground:-#ffffff}; \
bar $bar_id colors focused_workspace ${color1:-#ff0000} ${color1:-#ff0000} ${color0:-#222222}; \
bar $bar_id colors active_workspace ${color2:-#333333} ${color2:-#333333} ${color0:-#222222}; \
bar $bar_id colors inactive_workspace ${color0:-#222222} ${color0:-#222222} ${color7:-#ffffff}; \
bar $bar_id colors urgent_workspace ${color4:-#666666} ${color4:-#666666} ${color0:-#222222}" >/dev/null 2>&1 || true
      ;;
    esac
  fi

  # dconf writes; only new apps and libadwaita read these.
  (
    gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark"
    gsettings set org.gnome.desktop.interface font-name "JetBrainsMono Nerd Font 13"
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
    gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
    gsettings set org.gnome.desktop.interface cursor-theme "Doro"
    gsettings set org.gnome.desktop.interface cursor-size 32
  ) >/dev/null 2>&1 9>&- &
}

if [ "$restore" -eq 1 ]; then
  if [ -f "$WAL_DIR/colors" ]; then
    apply_theme ""
  else
    pgrep -x swayosd-server >/dev/null || nohup swayosd-server >/dev/null 2>&1 9>&- &
  fi
  exit 0
fi

# %f may be a bare filename, so resolve it before trusting it.
arg="$want"
if [ -n "$want" ] && [ ! -f "$want" ]; then
  if [ -f "$PWD/$want" ]; then
    arg="$PWD/$want"
  else
    arg=$(find "$HOME/pictures/wallpapers" -name "$(basename "$want")" -type f -print -quit 2>/dev/null || true)
  fi
fi

[ -n "$arg" ] && [ -f "$arg" ] || {
  notify_error "cannot read ${want:-<no argument>}"
  exit 1
}
target=$(readlink -f "$arg")

# Append is atomic under PIPE_BUF, so concurrent clicks cannot interleave and
# the append order is the click order. flock is deliberately not used here: it
# hands the lock out in no particular order, so an older click could win.
# Only the newest line is ever read, so trim instead of growing forever.
if [ -f "$REQUESTS" ] && [ "$(wc -l <"$REQUESTS")" -gt 64 ]; then
  printf '%s\n' "$(tail -n 1 "$REQUESTS")" >"$REQUESTS.tmp" &&
    mv -f "$REQUESTS.tmp" "$REQUESTS"
fi
printf '%s\n' "$target" >>"$REQUESTS"

# Paint first, but only while this click is still the newest one. Pushing the
# real image path keeps the preview from disagreeing with what pywal records.
if [ "$(tail -n 1 "$REQUESTS" 2>/dev/null || true)" = "$target" ]; then
  swaymsg output '*' bg "$target" fill >/dev/null 2>&1 || true
fi

# Coalescing worker: one at a time, always draining the newest request, so a
# burst of clicks collapses into the last one instead of queueing every theme.
(
  flock -w 60 9 || exit 0
  while :; do
    want=$(tail -n 1 "$REQUESTS" 2>/dev/null || true)
    [ -n "$want" ] || break
    [ "$want" = "$(cat "$APPLIED" 2>/dev/null || true)" ] && break
    apply_theme "$want"
    printf '%s\n' "$want" >"$APPLIED"
  done

  # Reconcile: a click that arrived mid-flight may have painted the screen
  # without pywal catching up, so point the symlink at what was last applied.
  settled=$(cat "$APPLIED" 2>/dev/null || true)
  if [ -n "$settled" ] && [ "$(readlink "$WAL_DIR/bg" 2>/dev/null || true)" != "$settled" ]; then
    ln -sf "$settled" "$WAL_DIR/bg"
    swaymsg output '*' bg "$WAL_DIR/bg" fill >/dev/null 2>&1 || true
  fi
) 9>"$WAL_DIR/.lock"
