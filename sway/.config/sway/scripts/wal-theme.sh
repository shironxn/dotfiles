#!/bin/sh
# Wal wrapper: apply theme + reload services
# Called from:
#   autostart (-R / --restore): restore previous theme on sway start
#   wallpaper.sh (-i img): apply new wallpaper theme
set -eu

RESTORE=false
case "${1:-}" in -R|--restore) RESTORE=true;; esac

# Guard: skip on first run (no pywal session yet)
if $RESTORE && [ ! -f ~/.cache/wal/colors ]; then
  echo '[wal-theme] No pywal session to restore; skipping.'
  killall swaybg 2>/dev/null || true
  nohup swaybg -c '#000000' -m fill &>/dev/null &
  exit 0
fi

# Run pywal
if $RESTORE; then
  timeout 120 wal "$@" 2>/dev/null || echo '[wal-theme] wal restore skipped'
else
  timeout 120 wal "$@" 2>/dev/null || echo '[wal-theme] wal skipped, using cached colors'
fi

# Exit early if no colors were generated
[ ! -f ~/.cache/wal/colors ] && exit 0

# Mako, Swaylock, GTK: symlink to pywal cache (replaces sed/cp/heredoc)
[ -f ~/.cache/wal/colors-mako ] && ln -sf ~/.cache/wal/colors-mako ~/.config/mako/config
[ -f ~/.cache/wal/colors-swaylock ] && ln -sf ~/.cache/wal/colors-swaylock ~/.config/swaylock/config
# GTK: tidak di-wal lagi — adw-gtk3 + color-scheme (konsisten GTK3/4, lihat audit 06)
makoctl reload 2>/dev/null || true

# SwayOSD: symlink to pywal cache + restart server
[ -f ~/.cache/wal/style-swayosd.css ] && ln -sf ~/.cache/wal/style-swayosd.css ~/.config/swayosd/style.css

killall -q swayosd-server 2>/dev/null || true
nohup swayosd-server --style ~/.config/swayosd/style.css &>/dev/null &

# Foot: signal reload for new colors
killall -USR1 foot 2>/dev/null || true


# Wallpaper: update symlink for Sway native background handling
if [ -f ~/.cache/wal/wal ]; then
  ln -sf "$(cat ~/.cache/wal/wal)" ~/.cache/wal/bg
fi

# Reload sway (only when changing wallpaper, not on startup)
if ! $RESTORE; then
  swaymsg reload 2>/dev/null || true
fi


# GSettings sync
gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3" 2>/dev/null || true
gsettings set org.gnome.desktop.interface font-name "JetBrainsMono Nerd Font 10" 2>/dev/null || true
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark" 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-theme "Doro" 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-size 32 2>/dev/null || true
