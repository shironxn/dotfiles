#!/bin/sh
# Apply a pywal theme and reload every dependent service.
#   wal-theme.sh -i <image>   select a new wallpaper
#   wal-theme.sh -R           restore the previous theme at login
set -eu

restore=0
case "${1:-}" in
-R | --restore) restore=1 ;;
esac

WAL_DIR="$HOME/.cache/wal"
CONFIG="$HOME/.config"

if [ "$restore" -eq 1 ] && [ ! -f "$WAL_DIR/colors" ]; then
  echo '[wal-theme] no pywal session to restore'
  exit 0
fi

timeout 120 wal "$@" 2>/dev/null || echo '[wal-theme] wal failed, keeping cached colors'
[ -f "$WAL_DIR/colors" ] || exit 0

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
nohup swayosd-server --style "$CONFIG/swayosd/style.css" >/dev/null 2>&1 &

killall -USR1 foot 2>/dev/null || true

# Sway reads the wallpaper from this symlink; swaylock uses the blurred copy.
if [ -f "$WAL_DIR/wal" ]; then
  wallpaper=$(cat "$WAL_DIR/wal")
  ln -sf "$wallpaper" "$WAL_DIR/bg"
  magick "$wallpaper" -scale 1920x1080^ -gravity center -extent 1920x1080 \
    -filter Gaussian -blur 0x8 -fill black -colorize 40% \
    "$WAL_DIR/bg-lock.jpg" 2>/dev/null || true
  # swaylock does not expand ~ in config values, so patch the path into the
  # generated file itself. sed -i replaces the inode, which would break the
  # symlink we just created.
  if [ -f "$WAL_DIR/colors-swaylock" ]; then
    sed -i '\|^image=|d' "$WAL_DIR/colors-swaylock"
    printf 'image=%s\n' "$WAL_DIR/bg-lock.jpg" >>"$WAL_DIR/colors-swaylock"
  fi
fi

if [ "$restore" -eq 0 ]; then
  swaymsg reload 2>/dev/null || true
fi

gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark" 2>/dev/null || true
gsettings set org.gnome.desktop.interface font-name "JetBrainsMono Nerd Font 13" 2>/dev/null || true
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark" 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-theme "Doro" 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-size 32 2>/dev/null || true
