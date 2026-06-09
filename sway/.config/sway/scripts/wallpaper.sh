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

wal -i "$wallpaper" && swaymsg reload
