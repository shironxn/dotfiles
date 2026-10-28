#!/bin/sh
# Brightness: internal panel through swayosd, external monitor through ddcutil.
# Usage: brightness-switch.sh up|down [step]
set -eu

case "${1:-}" in
up | down) ;;
*) echo "usage: $0 up|down [step]" >&2; exit 1 ;;
esac

step="${2:-5}"
output=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name')

if [ "$output" = "eDP-1" ]; then
  if [ "$1" = "up" ]; then
    swayosd-client --brightness raise --device intel_backlight
  else
    swayosd-client --brightness lower --device intel_backlight
  fi
  exit 0
fi

[ "$output" = "HDMI-A-2" ] || exit 0

if ! command -v ddcutil >/dev/null; then
  swayosd-client --custom-icon=display-brightness-symbolic --custom-message="ddcutil missing"
  exit 1
fi

CACHE="$HOME/.cache/brightness-hdmi"
read_level() {
  ddcutil -d 1 getvcp 10 --brief 2>/dev/null | awk '{print $4}'
}

level=$(cat "$CACHE" 2>/dev/null || echo '')
case "$level" in '' | *[!0-9]*) level=$(read_level) ;; esac
if [ -n "$(find "$CACHE" -mmin +60 2>/dev/null)" ]; then
  level=$(read_level)
fi
if [ -z "$level" ]; then
  swayosd-client --custom-icon=display-brightness-symbolic --custom-message="ddcutil read failed"
  exit 1
fi

if [ "$1" = "up" ]; then
  level=$((level + step))
  if [ "$level" -gt 100 ]; then level=100; fi
else
  level=$((level - step))
  if [ "$level" -lt 0 ]; then level=0; fi
fi
echo "$level" > "$CACHE"

ddcutil --sleep-multiplier=0.5 -d 1 setvcp 10 "$level" >/dev/null 2>&1 &
swayosd-client --custom-progress="$(awk -v v="$level" 'BEGIN { printf "%.2f", v / 100 }')" \
  --custom-icon=display-brightness-symbolic
