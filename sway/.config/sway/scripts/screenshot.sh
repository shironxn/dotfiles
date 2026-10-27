#!/bin/sh
# Screenshot — simple & clean (no annotate, no recording)
set -eu

dir="$HOME/pictures/screenshots"
mkdir -p "$dir"
file="$dir/$(date +'%Y-%m-%d_%H-%M-%S')"

choice=$(printf "Area\\0icon\\037edit-select\\nWindow\\0icon\\037window\\nDisplay\\0icon\\037video-display" | pick-fuzzel " screenshot ")

case "$choice" in
    *Area*)
        region=$(slurp) || exit 0
        grim -g "$region" "$file.png" || exit 0
        notify-send -t 2000 "Screenshot" "Area: $(basename "$file.png")"
        wl-copy < "$file.png" &
        ;;
    *Window*)
        grim -g "$(swaymsg -t get_tree | jq -r '.. | select(.focused? == true).rect | "\(.x),\(.y) \(.width)x\(.height)"')" "$file.png" || exit 0
        notify-send -t 2000 "Screenshot" "Window: $(basename "$file.png")"
        wl-copy < "$file.png" &
        ;;
    *Display*)
        grim -o "$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name')" "$file.png" || exit 0
        notify-send -t 2000 "Screenshot" "Display: $(basename "$file.png")"
        wl-copy < "$file.png" &
        ;;
    *)
        exit 0
        ;;
esac
