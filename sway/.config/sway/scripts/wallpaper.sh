#!/bin/sh
# Wallpaper picker with pywal theme sync
#
# Primary UI is wallpaper-picker.py (GTK3, two-pane with live preview). It
# prints the full path of the chosen image, so no name resolution is needed.
# fuzzel is kept as a fallback: if the GTK toolchain is missing or the picker
# fails to start, a bare basename comes back instead and is resolved below.

dir="$HOME/pictures/wallpapers"
[ ! -d "$dir" ] && notify-send "Wallpaper" "Dir not found" && exit 1

files=$(find "$dir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \))
[ -z "$files" ] && notify-send "Wallpaper" "No images in $dir" && exit 1

# Fallback picker: pick-fuzzel returns a bare basename, so map it back to a path.
pick_with_fuzzel() {
  selection=$(printf '%s\n' "$files" | while IFS= read -r f; do
    printf "%s\000icon\037image-x-generic\n" "$(basename "$f")"
  done | pick-fuzzel " wallpaper " -w 70 -l 20)
  [ -z "$selection" ] && return 0
  printf '%s\n' "$files" | while IFS= read -r f; do
    [ "${f##*/}" = "$selection" ] && { printf '%s\n' "$f"; break; }
  done
}

picker="$HOME/.config/sway/scripts/wallpaper-picker.py"
wallpaper=""

if [ -x "$picker" ]; then
  wallpaper=$(printf '%s\n' "$files" | "$picker" 2>/dev/null)
  if [ $? -eq 0 ]; then
    # GTK ran to completion: no output means the user pressed Escape.
    [ -z "$wallpaper" ] && exit 0
  else
    wallpaper=""
  fi
fi

if [ -z "$wallpaper" ]; then
  wallpaper=$(pick_with_fuzzel)
  [ -z "$wallpaper" ] && notify-send "Wallpaper" "Not found" && exit 1
fi

# Apply theme via wal-theme.sh (handles wal + services + reload)
~/.config/sway/scripts/wal-theme.sh -i "$wallpaper"
