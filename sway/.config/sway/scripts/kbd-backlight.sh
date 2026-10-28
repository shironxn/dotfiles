#!/bin/sh
# Keyboard backlight control with OSD notification
# Usage: kbd-backlight.sh up|down
set -eu

case "${1:-}" in
up | down) ;;
*) echo "usage: $0 up|down" >&2; exit 1 ;;
esac

if ! command -v brightnessctl >/dev/null; then
  exit 1
fi

# Detect keyboard backlight LED device (ThinkPad, Dell, Asus, Apple, generic)
DEV=""
for d in /sys/class/leds/tpacpi::kbd_backlight /sys/class/leds/*kbd*backlight* /sys/class/leds/*::kbd_backlight; do
  if [ -d "$d" ]; then
    DEV=$(basename "$d")
    break
  fi
done

if [ -z "$DEV" ]; then
  exit 0
fi

if [ "$1" = "up" ]; then
  brightnessctl -q -d "$DEV" set +1 2>/dev/null || true
else
  brightnessctl -q -d "$DEV" set 1- 2>/dev/null || true
fi

level=$(cat "/sys/class/leds/$DEV/brightness" 2>/dev/null || echo 0)
case "$level" in
0) msg="KBD Off" ;;
1) msg="KBD Low" ;;
*) msg="KBD High" ;;
esac

notify-send -t 1200 -h string:x-canonical-private-synchronous:osd "󰌌 $msg"
