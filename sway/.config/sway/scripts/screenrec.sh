#!/bin/sh
# Screen recorder toggle script using wf-recorder
set -eu

# If already recording, stop gracefully
if pgrep -x wf-recorder >/dev/null; then
    killall -INT wf-recorder
    notify-send -t 3000 -i media-record "Screen Recorder" "Recording stopped and saved to ~/videos/recordings/"
    exit 0
fi

dir="$HOME/videos/recordings"
mkdir -p "$dir"
file="$dir/rec_$(date +'%Y-%m-%d_%H-%M-%S').mp4"

# Pywal styling for slurp selection
slurp_args=""
if [ -f "$HOME/.cache/wal/colors" ]; then
    color4=$(sed -n '5p' "$HOME/.cache/wal/colors")
    slurp_args="-b #00000088 -c ${color4}ff -s ${color4}22 -w 2"
fi

choice=$(printf "Area (Video only)\\0icon\\037edit-select\\nArea + Audio\\0icon\\037audio-input-microphone\\nWindow\\0icon\\037window\\nDisplay\\0icon\\037video-display\\nDisplay + Audio\\0icon\\037audio-input-microphone" | pick-fuzzel " record ")

case "$choice" in
    *"Area (Video only)"*)
        region=$(slurp $slurp_args) || exit 0
        notify-send -t 2500 -i media-record "Screen Recorder" "Recording area started...\nPress Super+Shift+r to stop."
        wf-recorder -g "$region" -f "$file" &
        ;;
    *"Area + Audio"*)
        region=$(slurp $slurp_args) || exit 0
        notify-send -t 2500 -i media-record "Screen Recorder" "Recording area + audio started...\nPress Super+Shift+r to stop."
        wf-recorder -a -g "$region" -f "$file" &
        ;;
    *Window*)
        geom=$(swaymsg -t get_tree | jq -r '.. | select(.focused? == true).rect | "\(.x),\(.y) \(.width)x\(.height)"') || exit 0
        notify-send -t 2500 -i media-record "Screen Recorder" "Recording window started...\nPress Super+Shift+r to stop."
        wf-recorder -g "$geom" -f "$file" &
        ;;
    *"Display (Video only)"*)
        output=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name') || exit 0
        notify-send -t 2500 -i media-record "Screen Recorder" "Recording display started...\nPress Super+Shift+r to stop."
        wf-recorder -o "$output" -f "$file" &
        ;;
    *"Display + Audio"*)
        output=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name') || exit 0
        notify-send -t 2500 -i media-record "Screen Recorder" "Recording display + audio started...\nPress Super+Shift+r to stop."
        wf-recorder -a -o "$output" -f "$file" &
        ;;
    *)
        exit 0
        ;;
esac
