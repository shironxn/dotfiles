#!/bin/sh
# Save a screenshot of an area, window, or display.
set -eu

dir="$HOME/pictures/screenshots"
mkdir -p "$dir"
file="$dir/$(date +'%Y-%m-%d_%H-%M-%S_%3N')"

slurp_args=""
if [ -f "$HOME/.cache/wal/colors" ]; then
  accent=$(sed -n '5p' "$HOME/.cache/wal/colors")
  slurp_args="-b #00000088 -c ${accent}ff -s ${accent}22 -w 2"
fi

choice=$(printf 'Area\0icon\037edit-select\nWindow\0icon\037window\nDisplay\0icon\037video-display' |
  pick-fuzzel " screenshot ")

shot() {
  label=$1
  shift
  grim "$@" "$file.png" || exit 0
  wl-copy --type image/png <"$file.png"
  notify-send -t 2000 "Screenshot" "$label: $(basename "$file.png")"
}

case "$choice" in
*Area*)
  # shellcheck disable=SC2086
  region=$(slurp $slurp_args) || exit 0
  shot Area -g "$region"
  ;;
*Window*)
  geom=$(swaymsg -t get_tree |
    jq -r '.. | select(.focused? == true).rect | "\(.x),\(.y) \(.width)x\(.height)"') || exit 0
  shot Window -g "$geom"
  ;;
*Display*)
  output=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name') || exit 0
  shot Display -o "$output"
  ;;
*) exit 0 ;;
esac
