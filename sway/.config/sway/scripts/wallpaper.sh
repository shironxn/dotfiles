#!/bin/sh

dir="$HOME/Pictures/Wallpapers"
[ ! -d "$dir" ] && notify-send "Wallpaper" "Dir not found" && exit 1

files=$(find "$dir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \))

selection=$(echo "$files" | while IFS= read -r f; do
  printf "%s\000icon\037image-x-generic\n" "$(basename "$f")"
done | fuzzel -d -p "Wallpaper: ")

[ -z "$selection" ] && exit 0

wallpaper=$(echo "$files" | grep -F "/$selection" | head -1)
[ -z "$wallpaper" ] && notify-send "Wallpaper" "Not found" && exit 1

PYTHONPATH=/tmp/pywal-venv/lib/python3.14/site-packages wal --backend colorthief -i "$wallpaper" || exit 1

# swayosd baru udah regenerate, restart biar kebaca
killall swayosd-server 2>/dev/null || true
swayosd-server --style ~/.config/swayosd/style.css &
disown

swaymsg reload
