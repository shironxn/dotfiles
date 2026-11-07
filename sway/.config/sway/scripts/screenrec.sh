#!/bin/sh
# Screen recorder toggle script using wf-recorder with desktop audio capture
set -eu

RT="${XDG_RUNTIME_DIR:-/tmp}/sway"; mkdir -p "$RT"
REC_START_FILE="$RT/rec-start"

# If already recording, stop gracefully
if pgrep -x wf-recorder >/dev/null; then
    killall -INT wf-recorder
    rm -f "$REC_START_FILE"
    notify-send -t 3000 -i media-record "Screen Recorder" "Recording stopped and saved to ~/videos/recordings/"
    exit 0
fi

dir="$HOME/videos/recordings"
mkdir -p "$dir"
file="$dir/rec_$(date +'%Y-%m-%d_%H-%M-%S').mp4"

# Capture desktop/system audio directly from default sink monitor (no mic noise)
audio_args=""
audio_sink=$(pactl get-default-sink 2>/dev/null || true)
if [ -n "$audio_sink" ]; then
    audio_args="--audio=${audio_sink}.monitor"
fi

# Pywal styling for slurp selection
slurp_args=""
if [ -f "$HOME/.cache/wal/colors" ]; then
    color4=$(sed -n '5p' "$HOME/.cache/wal/colors")
    slurp_args="-b #00000088 -c ${color4}ff -s ${color4}22 -w 2"
fi

choice=$(printf "Area\\0icon\\037edit-select\\nWindow\\0icon\\037window\\nDisplay\\0icon\\037video-display" | pick-fuzzel " record ")

case "$choice" in
    *Area*)
        region=$(slurp $slurp_args) || exit 0
        date +%s > "$REC_START_FILE"
        notify-send -t 2500 -i media-record "Screen Recorder" "Recording area started...\nPress Super+Shift+r to stop."
        # shellcheck disable=SC2086
        wf-recorder $audio_args -g "$region" -f "$file" &
        ;;
    *Window*)
        geom=$(swaymsg -t get_tree | jq -r '.. | select(.focused? == true).rect | "\(.x),\(.y) \(.width)x\(.height)"') || exit 0
        date +%s > "$REC_START_FILE"
        notify-send -t 2500 -i media-record "Screen Recorder" "Recording window started...\nPress Super+Shift+r to stop."
        # shellcheck disable=SC2086
        wf-recorder $audio_args -g "$geom" -f "$file" &
        ;;
    *Display*)
        output=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name') || exit 0
        date +%s > "$REC_START_FILE"
        notify-send -t 2500 -i media-record "Screen Recorder" "Recording display started...\nPress Super+Shift+r to stop."
        # shellcheck disable=SC2086
        wf-recorder $audio_args -o "$output" -f "$file" &
        ;;
    *)
        exit 0
        ;;
esac
