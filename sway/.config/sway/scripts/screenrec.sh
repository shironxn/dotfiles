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

choice=$(printf "Area\\0icon\\037edit-select\\nDisplay\\0icon\\037video-display\\nArea + Mic\\0icon\\037audio-input-microphone" | pick-fuzzel " record ")

case "$choice" in
    *"Area + Mic"*)
        region=$(slurp $slurp_args) || exit 0
        notify-send -t 2500 -i media-record "Screen Recorder" "Recording area + mic started...\nPress Super+Shift+r to stop."
        wf-recorder -a -g "$region" -f "$file" &
        ;;
    *Area*)
        region=$(slurp $slurp_args) || exit 0
        notify-send -t 2500 -i media-record "Screen Recorder" "Recording area started...\nPress Super+Shift+r to stop."
        wf-recorder -g "$region" -f "$file" &
        ;;
    *Display*)
        output=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name') || exit 0
        notify-send -t 2500 -i media-record "Screen Recorder" "Recording display started...\nPress Super+Shift+r to stop."
        wf-recorder -o "$output" -f "$file" &
        ;;
    *)
        exit 0
        ;;
esac
