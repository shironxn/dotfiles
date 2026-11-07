#!/bin/sh
# Brightness control: internal panels via swayosd, external monitors via ddcutil.
# Usage: brightness-switch.sh up|down [step]
set -eu

case "${1:-}" in
up | down) ;;
*) echo "usage: $0 up|down [step]" >&2; exit 1 ;;
esac

step="${2:-5}"
output=$(swaymsg -t get_outputs 2>/dev/null | jq -r '.[] | select(.focused) | .name' 2>/dev/null || true)

# Internal laptop panels (eDP, LVDS, DSI) control hardware backlight directly
case "$output" in
eDP* | LVDS* | DSI* | "")
  if [ "$1" = "up" ]; then
    swayosd-client --brightness raise
  else
    swayosd-client --brightness lower
  fi
  exit 0
  ;;
esac

# External monitors: communicate over I2C via DDC/CI
if ! command -v ddcutil >/dev/null; then
  swayosd-client --custom-icon=display-brightness-symbolic --custom-message="ddcutil missing"
  exit 1
fi

CACHE="$HOME/.cache/brightness-$output"
read_level() {
  ddcutil getvcp 10 --brief 2>/dev/null | awk '{print $4}'
}

level=$(cat "$CACHE" 2>/dev/null || echo '')
case "$level" in '' | *[!0-9]*) level=$(read_level) ;; esac
if [ -n "$(find "$CACHE" -mmin +60 2>/dev/null)" ]; then
  level=$(read_level)
fi
if [ -z "$level" ]; then
  swayosd-client --custom-icon=display-brightness-symbolic --custom-message="DDC read failed"
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

# DDC writes are slow (~0.5s), so run them detached. If the write fails, drop
# the cached level so the next press re-reads the monitor instead of trusting
# a value that never landed.
(
  ddcutil --sleep-multiplier=0.5 setvcp 10 "$level" >/dev/null 2>&1 || rm -f "$CACHE"
) &

swayosd-client --custom-progress="$(awk -v v="$level" 'BEGIN { printf "%.2f", v / 100 }')" \
  --custom-icon=display-brightness-symbolic
