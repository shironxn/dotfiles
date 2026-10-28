#!/bin/sh
# Keyboard backlight OSD. Volume, brightness and microphone are handled by
# swayosd-client directly from the keybinds.
set -eu

DEV="tpacpi::kbd_backlight"

case "${1:-}" in
kbd) ;;
*) echo "usage: $0 kbd up|down" >&2; exit 1 ;;
esac
case "${2:-}" in
up | down) ;;
*) echo "usage: $0 kbd up|down" >&2; exit 1 ;;
esac

if ! command -v brightnessctl >/dev/null; then
  swayosd-client --custom-icon=keyboard-brightness-symbolic --custom-message="brightnessctl missing"
  exit 1
fi

if ! brightnessctl -l 2>/dev/null | grep -q "$DEV"; then
  swayosd-client --custom-icon=keyboard-brightness-symbolic --custom-message="No keyboard backlight"
  exit 0
fi

if [ "$2" = "up" ]; then
  brightnessctl -d "$DEV" set +1 >/dev/null 2>&1 || true
else
  brightnessctl -d "$DEV" set 1- >/dev/null 2>&1 || true
fi

level=$(cat "/sys/class/leds/$DEV/brightness" 2>/dev/null || echo 0)
case "$level" in
0) msg="KBD Off" ;;
1) msg="KBD Low" ;;
*) msg="KBD High" ;;
esac

notify-send -t 1200 -h string:x-canonical-private-synchronous:osd "󰌌 $msg"
