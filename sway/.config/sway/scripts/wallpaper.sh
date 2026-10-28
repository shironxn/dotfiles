#!/bin/sh
# Wallpaper picker. The GTK picker returns a full path; fuzzel is the fallback.
set -eu

dir="$HOME/pictures/wallpapers"
gtk_picker="$HOME/.config/sway/scripts/wallpaper-picker.py"

[ -d "$dir" ] || { notify-send "Wallpaper" "$dir not found"; exit 1; }

files=$(find "$dir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \))
[ -n "$files" ] || { notify-send "Wallpaper" "No images in $dir"; exit 1; }

choose_fuzzel() {
  selection=$(printf '%s\n' "$files" | while IFS= read -r f; do
    printf '%s\000icon\037image-x-generic\n' "${f##*/}"
  done | pick-fuzzel " wallpaper " -w 70 -l 20)
  [ -n "$selection" ] || return 1
  printf '%s\n' "$files" | while IFS= read -r f; do
    if [ "${f##*/}" = "$selection" ]; then
      printf '%s\n' "$f"
      return 0
    fi
  done
  return 1
}

wallpaper=""
if [ -x "$gtk_picker" ]; then
  wallpaper=$(export PYTHONDONTWRITEBYTECODE=1; printf '%s\n' "$files" | "$gtk_picker" 2>/dev/null) || wallpaper=""
fi
[ -n "$wallpaper" ] || wallpaper=$(choose_fuzzel) || exit 0

~/.config/sway/scripts/wal-theme.sh -i "$wallpaper"
