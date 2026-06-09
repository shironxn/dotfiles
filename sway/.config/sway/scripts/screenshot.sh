#!/bin/sh

dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
file="$dir/$(date +'%Y-%m-%d_%H-%M-%S').png"

choice=$(printf "Area\000icon\037edit-select\nWindow\000icon\037window\nDisplay\000icon\037video-display" | fuzzel -d -p "Screenshot: ")

case "$choice" in
    *Area)
        grim -g "$(slurp)" "$file"
        ;;
    *Window)
        grim -g "$(swaymsg -t get_tree | jq -r '.. | select(.focused? == true).rect | "\(.x),\(.y) \(.width)x\(.height)"')" "$file"
        ;;
    *Display)
        output=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name')
        grim -o "$output" "$file"
        ;;
    *)
        exit 0
        ;;
esac

wl-copy < "$file" && notify-send "Screenshot" "Captured: $(basename "$file")"
