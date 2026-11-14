#!/bin/sh
# Apply a pywal palette and refresh everything that consumes it.
#   wallpaper.sh -i <image>   select a new wallpaper
#   wallpaper.sh -R           restore the last session at login
set -eu

WAL="$HOME/.cache/wal"
CONF="$HOME/.config"
REQUESTS="$WAL/.requests"
APPLIED="$WAL/.applied"
mkdir -p "$WAL"

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

run_wal() {
  # A template symlink left behind by a deleted repo file makes wal crash on
  # every export, so sweep those first.
  find "$CONF/wal/templates" -xtype l -delete 2>/dev/null || true
  # -n: pywal must not spawn its own swaybg. sway owns the wallpaper through the
  #     `output * bg` rule and a second swaybg races it for the screen.
  # -e: pywal must not run `swaymsg reload`. That reload re-runs autostart.conf,
  #     which calls this script again, which calls wal again.
  if [ -n "${1:-}" ]; then
    timeout 120 wal -n -e -i "$1" 2>/dev/null ||
      notify_error "pywal failed on $(basename "$1")"
  else
    timeout 120 wal -n -e -R 2>/dev/null ||
      printf '[wallpaper] no cached palette to restore\n' >&2
  fi
}

link_colours() {
  # pywal only writes into ~/.cache/wal; the target dirs come from stow, and
  # swayosd never creates its own.
  mkdir -p "$CONF/swayosd"
  for pair in \
    "colors-mako:$CONF/mako/config" \
    "colors-swaylock:$CONF/swaylock/config" \
    "colors-gtk.css:$CONF/gtk-3.0/gtk.css" \
    "style-swayosd.css:$CONF/swayosd/style.css"; do
    src="$WAL/${pair%%:*}"
    [ -f "$src" ] && ln -sf "$src" "${pair#*:}"
  done
  makoctl reload 2>/dev/null || true
}

restart_swayosd() {
  # The daemon outlives this script, so it must not inherit the lock fd: an
  # inherited fd 9 keeps the lock held forever and stalls every later click.
  killall -q -w swayosd-server 2>/dev/null || true
  nohup swayosd-server --style "$CONF/swayosd/style.css" >/dev/null 2>&1 9>&- &
}

paint() {
  # $1 = image, empty to reuse whatever pywal recorded in $WAL/wal.
  image=${1:-$(cat "$WAL/wal" 2>/dev/null || true)}
  [ -n "$image" ] || return 0
  ln -sf "$image" "$WAL/bg"
  swaymsg output '*' bg "$WAL/bg" fill >/dev/null 2>&1 || true
}

blur_lock() {
  # Detached, because the render costs about a second. swaylock's config is only
  # patched once the image exists, so a failure cannot leave a dangling image=.
  image=$(cat "$WAL/wal" 2>/dev/null || true)
  [ -n "$image" ] || return 0
  res=$(swaymsg -t get_outputs 2>/dev/null | jq -r '
    [.[] | select(.active) | .rect] | max_by(.width * .height) | "\(.width)x\(.height)"
  ' 2>/dev/null || true)
  res=${res:-1920x1080}
  (
    magick "$image" -scale "$res^" -gravity center -extent "$res" \
      -scale 25% -blur 0x3 -scale 400% -fill black -colorize 40% \
      "$WAL/bg-lock.jpg" 2>/dev/null &&
      [ -s "$WAL/bg-lock.jpg" ] && [ -f "$WAL/colors-swaylock" ] || exit 0
    sed -i '\|^image=|d' "$WAL/colors-swaylock"
    printf 'image=%s\n' "$WAL/bg-lock.jpg" >>"$WAL/colors-swaylock"
  ) 9>&- &
}

sway_colours() {
  [ -f "$WAL/colors-sway" ] || return 0
  # Only the generated `set $name #rrggbb` pairs reach eval, and the awk filter
  # pins both sides of the assignment, so nothing else can be spliced in.
  eval "$(awk '$1 == "set" && $2 ~ /^\$[a-z0-9]+$/ && $3 ~ /^#[0-9a-fA-F]{6}$/ {
    sub(/^\$/, "", $2); printf "%s=%s\n", $2, $3 }' "$WAL/colors-sway")"

  fg=${foreground:-#ffffff}
  c0=${color0:-#222222}
  c1=${color1:-#ff0000}
  c2=${color2:-#333333}
  c4=${color4:-#666666}
  c6=${color6:-#999999}
  c7=${color7:-#ffffff}
  c8=${color8:-#333333}

  # Border colours over IPC. `swaymsg reload` would re-run autostart.conf at
  # about 1.7s; these round-trips cost about 15ms together.
  swaymsg "client.focused $c4 $c4 $fg $c4 $c6; \
client.focused_inactive $c8 $c8 $fg $c8 $c8; \
client.unfocused $c0 $c0 $fg $c0 $c0; \
client.urgent $c1 $c1 $fg $c1 $c1" >/dev/null 2>&1 || true

  # The bar reads its palette from bar.conf, which is only re-parsed on reload,
  # so push the same values directly. One bar is assumed.
  bar=$(swaymsg -t get_bar_config 2>/dev/null |
    jq -r 'if type == "array" then .[0] else . end' 2>/dev/null || true)
  case "$bar" in
  "" | null) return 0 ;;
  esac
  swaymsg "bar $bar colors background $c0; \
bar $bar colors statusline $fg; \
bar $bar colors focused_workspace $c1 $c1 $c0; \
bar $bar colors active_workspace $c2 $c2 $c0; \
bar $bar colors inactive_workspace $c0 $c0 $c7; \
bar $bar colors urgent_workspace $c4 $c4 $c0" >/dev/null 2>&1 || true
}

push_gsettings() {
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

apply_theme() {
  run_wal "${1:-}"
  [ -f "$WAL/colors" ] || return 0
  link_colours
  restart_swayosd
  paint "${1:-}"
  blur_lock
  sway_colours
  push_gsettings
}

if [ "$restore" -eq 1 ]; then
  if [ -f "$WAL/colors" ]; then
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

# swaymsg re-joins argv and parses the result as a Sway command, so a filename
# holding a command separator would be executed instead of painted.
if printf '%s' "$target" | grep -q '[;"[:cntrl:]]'; then
  notify_error "filename holds ; \" or a control character: $(basename "$target")"
  exit 1
fi

# Append is atomic under PIPE_BUF, so concurrent clicks cannot interleave and the
# append order is the click order. flock is deliberately not used here: it hands
# the lock out in no particular order, so an older click could win. Only the
# newest line is ever read, so trim instead of growing forever.
if [ -f "$REQUESTS" ] && [ "$(wc -l <"$REQUESTS")" -gt 64 ]; then
  printf '%s\n' "$(tail -n 1 "$REQUESTS")" >"$REQUESTS.tmp" &&
    mv -f "$REQUESTS.tmp" "$REQUESTS"
fi
printf '%s\n' "$target" >>"$REQUESTS"

# Paint first, but only while this click is still the newest one, so the preview
# never disagrees with what pywal ends up recording.
if [ "$(tail -n 1 "$REQUESTS" 2>/dev/null || true)" = "$target" ]; then
  swaymsg output '*' bg "$target" fill >/dev/null 2>&1 || true
fi

# Coalescing worker: one at a time, always draining the newest request, so a
# burst of clicks collapses into the last one instead of queueing every theme.
(
  flock -w 60 9 || exit 0
  while :; do
    next=$(tail -n 1 "$REQUESTS" 2>/dev/null || true)
    [ -n "$next" ] || break
    [ "$next" = "$(cat "$APPLIED" 2>/dev/null || true)" ] && break
    apply_theme "$next"
    printf '%s\n' "$next" >"$APPLIED"
  done

  # Reconcile: a click that landed mid-flight may have painted the screen
  # without pywal catching up, so point the symlink at what was last applied.
  settled=$(cat "$APPLIED" 2>/dev/null || true)
  if [ -n "$settled" ] && [ "$(readlink "$WAL/bg" 2>/dev/null || true)" != "$settled" ]; then
    ln -sf "$settled" "$WAL/bg"
    swaymsg output '*' bg "$WAL/bg" fill >/dev/null 2>&1 || true
  fi
) 9>"$WAL/.lock"
