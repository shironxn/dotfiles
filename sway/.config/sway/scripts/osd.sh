#!/bin/sh
# OSD — keyboard backlight via swayosd
# Volume, brightness, mic udah pake swayosd-client langsung dari keybinds
# Usage: osd.sh kbd up|down
set -eu

KBD_DEV="tpacpi::kbd_backlight"
KBD_MAX=$(cat /sys/class/leds/$KBD_DEV/max_brightness 2>/dev/null || echo 2)

case "${1:-}" in
  kbd)
    arg="${2:-}"
    if ! command -v brightnessctl >/dev/null; then
      swayosd-client --custom-icon=keyboard-brightness-symbolic --custom-message="brightnessctl not found"
      exit 1
    fi
    if ! brightnessctl -l 2>/dev/null | grep -q "$KBD_DEV"; then
      swayosd-client --custom-icon=keyboard-brightness-symbolic --custom-message="No keyboard backlight"
      exit 0
    fi
    case "$arg" in
      up)   brightnessctl -d "$KBD_DEV" set +1 2>/dev/null ;;
      down) brightnessctl -d "$KBD_DEV" set 1- 2>/dev/null ;;
      *)    echo "Usage: $0 kbd up|down" >&2; exit 1 ;;
    esac

    # Use mako notification (swayosd custom OSD has blank space on some overlays)
    K=$(cat /sys/class/leds/$KBD_DEV/brightness 2>/dev/null || echo 0)
    case "$K" in
      0) notify-send -t 1200 -h string:x-canonical-private-synchronous:osd "󰌌 KBD Off" ;;
      1) notify-send -t 1200 -h string:x-canonical-private-synchronous:osd "󰌌 KBD Low" ;;
      2) notify-send -t 1200 -h string:x-canonical-private-synchronous:osd "󰌌 KBD High" ;;
    esac
    ;;

  *)
    echo "Usage: $0 kbd up|down" >&2; exit 1 ;;
esac
