#!/bin/sh
# Toggle a screen recording with desktop audio, into ~/videos/recordings.
# The bar reads the elapsed time from the wf-recorder process itself, so no
# state is written here.
set -eu

if pgrep -x wf-recorder >/dev/null; then
  killall -INT wf-recorder
  notify-send -t 3000 -i media-record "Screen Recorder" \
    "Saved to ~/videos/recordings/"
  # Bound the wait: a wedged encoder must not leave the keybind hanging.
  waited=0
  while pgrep -x wf-recorder >/dev/null && [ "$waited" -lt 50 ]; do
    sleep 0.1
    waited=$((waited + 1))
  done
  [ "$waited" -lt 50 ] || pkill -9 -x wf-recorder
  exit 0
fi

dir="$HOME/videos/recordings"
mkdir -p "$dir"
file="$dir/rec_$(date +'%Y-%m-%d_%H-%M-%S').mp4"

# Desktop audio only: the sink monitor never picks up the microphone.
audio_args=""
sink=$(pactl get-default-sink 2>/dev/null || true)
[ -n "$sink" ] && audio_args="--audio=${sink}.monitor"

slurp_args=""
if [ -f "$HOME/.cache/wal/colors" ]; then
  accent=$(sed -n '5p' "$HOME/.cache/wal/colors")
  slurp_args="-b #00000088 -c ${accent}ff -s ${accent}22 -w 2"
fi

choice=$(printf 'Area\0icon\037edit-select\nWindow\0icon\037window\nDisplay\0icon\037video-display' |
  pick-fuzzel " record ")

start() {
  # shellcheck disable=SC2086 # $audio_args must word-split
  wf-recorder $audio_args "$@" -f "$file" &
  sleep 0.3
  if ! pgrep -x wf-recorder >/dev/null; then
    notify-send -u critical -t 3000 -i media-record "Screen Recorder" "Recording failed"
    exit 1
  fi
}

case "$choice" in
*Area*)
  # shellcheck disable=SC2086
  region=$(slurp $slurp_args) || exit 0
  start -g "$region"
  ;;
*Window*)
  geom=$(swaymsg -t get_tree |
    jq -r '.. | select(.focused? == true).rect | "\(.x),\(.y) \(.width)x\(.height)"') || exit 0
  start -g "$geom"
  ;;
*Display*)
  output=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name') || exit 0
  start -o "$output"
  ;;
*) exit 0 ;;
esac
