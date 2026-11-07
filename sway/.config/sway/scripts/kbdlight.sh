#!/bin/sh
# Keyboard backlight step. ThinkPad, Dell, Asus and Apple all expose a
# different LED name, so probe the common patterns.
#   kbdlight.sh up|down
set -eu

case "${1:-}" in
up | down) ;;
*)
  echo "usage: $0 up|down" >&2
  exit 1
  ;;
esac

command -v brightnessctl >/dev/null || exit 1

dev=""
for d in /sys/class/leds/tpacpi::kbd_backlight \
  /sys/class/leds/*kbd*backlight* \
  /sys/class/leds/*::kbd_backlight; do
  [ -d "$d" ] && dev=$(basename "$d") && break
done

# Desktops and most external keyboards have no backlight at all.
[ -n "$dev" ] || exit 0

if [ "$1" = up ]; then
  brightnessctl -q -d "$dev" set +1 2>/dev/null || true
else
  brightnessctl -q -d "$dev" set 1- 2>/dev/null || true
fi

cur=$(cat "/sys/class/leds/$dev/brightness" 2>/dev/null || echo 0)
max=$(cat "/sys/class/leds/$dev/max_brightness" 2>/dev/null || echo 1)
[ "$max" -gt 0 ] || max=1

case "$cur" in
0) msg="Off" ;;
1) msg="Low" ;;
*) msg="High" ;;
esac

swayosd-client \
  --custom-icon=keyboard-brightness-symbolic \
  --custom-message="KBD $msg" \
  --custom-progress="$(awk -v c="$cur" -v m="$max" 'BEGIN { printf "%.2f", c / m }')"
