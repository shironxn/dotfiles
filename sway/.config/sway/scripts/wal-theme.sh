#!/bin/sh
# Apply a pywal theme and refresh every dependent service.
#   wal-theme.sh -i <image>   select a new wallpaper
#   wal-theme.sh -R           restore the previous theme at login
set -eu

restore=0
case "${1:-}" in
-R | --restore) restore=1 ;;
esac

WAL_DIR="$HOME/.cache/wal"
CONFIG="$HOME/.config"
REQUESTS="$WAL_DIR/.requests"
APPLIED="$WAL_DIR/.applied"

if [ "$restore" -eq 1 ] && [ ! -f "$WAL_DIR/colors" ]; then
  echo '[wal-theme] no pywal session to restore'
  exit 0
fi

mkdir -p "$WAL_DIR"

apply_theme() {
  # $1 = image path, or empty to restore the cached session.
  if [ -n "$1" ]; then
    # -n: pywal must not spawn its own swaybg; sway owns the wallpaper through
    #     the output.conf `output * bg ~/.cache/wal/bg` rule.
    # -e: pywal must not call `swaymsg reload`. That reload re-runs
    #     autostart.conf, which calls `wal-theme.sh -R`, which calls `wal`
    #     again -> reload loop and two swaybg processes fighting over the
    #     screen.
    timeout 120 wal -n -e -i "$1" 2>/dev/null || {
      echo "[wal-theme] wal failed on $1" >&2
      command -v notify-send >/dev/null 2>&1 &&
        notify-send -u critical "Wallpaper" "pywal failed on $(basename "$1")"
    }
  else
    timeout 120 wal -n -e -R 2>/dev/null ||
      echo '[wal-theme] wal failed, keeping cached colors' >&2
  fi
  [ -f "$WAL_DIR/colors" ] || return 0

  # Generated configs that pywal owns: link them into place.
  for pair in \
    "colors-mako:$CONFIG/mako/config" \
    "colors-swaylock:$CONFIG/swaylock/config" \
    "colors-gtk.css:$CONFIG/gtk-3.0/gtk.css" \
    "style-swayosd.css:$CONFIG/swayosd/style.css"; do
    src="$WAL_DIR/${pair%%:*}"
    dst="${pair#*:}"
    if [ -f "$src" ]; then ln -sf "$src" "$dst"; fi
  done

  makoctl reload 2>/dev/null || true

  killall -q swayosd-server 2>/dev/null || true
  # Close the lock fd for the daemon: it outlives us, and an inherited fd would
  # keep the lock held forever, stalling every later run.
  nohup swayosd-server --style "$CONFIG/swayosd/style.css" >/dev/null 2>&1 9>&- &

  killall -USR1 foot 2>/dev/null || true

  if [ -f "$WAL_DIR/wal" ]; then
    wallpaper=$(cat "$WAL_DIR/wal")
    ln -sf "$wallpaper" "$WAL_DIR/bg"
    swaymsg output '*' bg "$WAL_DIR/bg" fill >/dev/null 2>&1 || true

    res=$(swaymsg -t get_outputs 2>/dev/null | jq -r '
      [.[] | select(.active) | .rect] | max_by(.width * .height) | "\(.width)x\(.height)"
    ' 2>/dev/null || true)
    res="${res:-1920x1080}"
    # Blur for the lockscreen runs detached; only patch swaylock's config once
    # the file exists, so a failed render cannot leave a dangling image= line.
    (
      if magick "$wallpaper" -scale "${res}^" -gravity center -extent "$res" \
        -scale 25% -blur 0x3 -scale 400% -fill black -colorize 40% \
        "$WAL_DIR/bg-lock.jpg" 2>/dev/null && [ -s "$WAL_DIR/bg-lock.jpg" ]; then
        if [ -f "$WAL_DIR/colors-swaylock" ]; then
          sed -i '\|^image=|d' "$WAL_DIR/colors-swaylock"
          printf 'image=%s\n' "$WAL_DIR/bg-lock.jpg" >>"$WAL_DIR/colors-swaylock"
        fi
      fi
    ) 9>&- &
  fi

  # Border colours, pushed over IPC instead of `swaymsg reload` (which re-runs
  # autostart.conf and costs ~1.9s). All four classes go in one round-trip.
  if [ -f "$WAL_DIR/colors-sway" ]; then
    while read -r key value; do
      case "$key" in
      color0 | color1 | color4 | color6 | color8 | foreground) export "$key=$value" ;;
      esac
    done <<EOF
$(sed -n 's/^set \$\([a-z0-9]*\) \(#[0-9a-fA-F]*\)$/\1 \2/p' "$WAL_DIR/colors-sway")
EOF
    swaymsg "client.focused ${color4:-#666666} ${color4:-#666666} ${foreground:-#ffffff} ${color4:-#666666} ${color6:-#999999}; \
client.focused_inactive ${color8:-#333333} ${color8:-#333333} ${foreground:-#ffffff} ${color8:-#333333} ${color8:-#333333}; \
client.unfocused ${color0:-#222222} ${color0:-#222222} ${foreground:-#ffffff} ${color0:-#222222} ${color0:-#222222}; \
client.urgent ${color1:-#ff0000} ${color1:-#ff0000} ${foreground:-#ffffff} ${color1:-#ff0000} ${color1:-#ff0000}" >/dev/null 2>&1 || true
  fi

  # GTK settings only matter to newly opened apps; keep them off the hot path.
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
  # Login restore: nothing is queued, apply the cached session directly.
  apply_theme ""
  exit 0
fi

# Resolve the argument. Thunar's %f can hand us a bare filename when its working
# directory is not the folder being browsed, which used to make this script exit
# silently and look like "nothing happens".
arg="${2:-}"
if [ -n "$arg" ] && [ ! -f "$arg" ]; then
  if [ -f "$PWD/$arg" ]; then
    arg="$PWD/$arg"
  else
    # Wallpapers live in nested folders; match on the bare name.
    found=$(find "$HOME/pictures/wallpapers" -name "$(basename "$arg")" -type f -print -quit 2>/dev/null || true)
    [ -n "$found" ] && arg="$found"
  fi
fi

if [ -z "$arg" ] || [ ! -f "$arg" ]; then
  notify() { command -v notify-send >/dev/null 2>&1 && notify-send -u critical "Wallpaper" "$*"; }
  notify "Cannot read ${arg:-<no argument>}"
  echo "[wal-theme] cannot read ${arg:-<no argument>}" >&2
  exit 1
fi

target=$(readlink -f "$arg")

# Publish the request. Appending one short line is atomic on Linux (O_APPEND,
# under PIPE_BUF), so concurrent clicks cannot interleave. Ordering is the
# append order, which is exactly the order the clicks happened.
# `flock` is not used for this: it hands the lock out in no particular order, so
# an older click could win the race and leave a stale wallpaper on screen.
# Only the newest line is ever read, so keep the file from growing forever.
if [ "$(wc -l <"$REQUESTS" 2>/dev/null || echo 0)" -gt 64 ]; then
  printf '%s\n' "$(tail -n 1 "$REQUESTS")" >"$REQUESTS.tmp" &&
    mv -f "$REQUESTS.tmp" "$REQUESTS"
fi
printf '%s\n' "$target" >>"$REQUESTS"

# Paint immediately, but only while this click is still the newest request.
# Pushing the real image path (not the shared `bg` symlink) keeps the early
# preview from disagreeing with what pywal ends up recording.
if [ "$(tail -n 1 "$REQUESTS" 2>/dev/null || true)" = "$target" ]; then
  swaymsg output '*' bg "$target" fill >/dev/null 2>&1 || true
fi

# Coalescing worker: one at a time, drains the newest request.
(
  flock -w 60 9 || exit 0
  while :; do
    want=$(tail -n 1 "$REQUESTS" 2>/dev/null || true)
    [ -n "$want" ] || break
    [ "$want" = "$(cat "$APPLIED" 2>/dev/null || true)" ] && break
    apply_theme "$want"
    printf '%s\n' "$want" >"$APPLIED"
  done

  # Final reconcile: make the shared symlink agree with what we last applied,
  # so a click that arrived mid-flight cannot leave the screen ahead of pywal.
  settled=$(cat "$APPLIED" 2>/dev/null || true)
  if [ -n "$settled" ] && [ "$(readlink "$WAL_DIR/bg" 2>/dev/null || true)" != "$settled" ]; then
    ln -sf "$settled" "$WAL_DIR/bg"
    swaymsg output '*' bg "$WAL_DIR/bg" fill >/dev/null 2>&1 || true
  fi
) 9>"$WAL_DIR/.lock"
