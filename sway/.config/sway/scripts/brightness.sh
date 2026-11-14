#!/bin/sh
# Brightness for the focused output: laptop panel via swayosd, external via DDC/CI.
#   brightness.sh up|down [step]
set -eu

case "${1:-}" in
up | down) ;;
*)
  echo "usage: $0 up|down [step]" >&2
  exit 1
  ;;
esac
step="${2:-5}"

output=$(swaymsg -t get_outputs 2>/dev/null | jq -r '.[] | select(.focused) | .name' 2>/dev/null || true)

# Internal panels expose a hardware backlight, which swayosd already drives.
case "$output" in
eDP* | LVDS* | DSI* | "")
  if [ "$1" = up ]; then
    swayosd-client --brightness raise
  else
    swayosd-client --brightness lower
  fi
  exit 0
  ;;
esac

if ! command -v ddcutil >/dev/null; then
  swayosd-client --custom-icon=display-brightness-symbolic --custom-message="ddcutil missing"
  exit 1
fi

# Reading over I2C takes ~0.5s, so cache the last known level per output. The
# fallback is per-uid: a shared /tmp/sway could be pre-created as a symlink.
cache="${XDG_RUNTIME_DIR:-/tmp}/sway-$(id -u)/brightness-$output"
mkdir -p "${cache%/*}"

read_level() {
  ddcutil getvcp 10 --brief 2>/dev/null | awk '{print $4}'
}

level=$(cat "$cache" 2>/dev/null || echo '')
case "$level" in '' | *[!0-9]*) level=$(read_level) ;; esac
[ -n "$(find "$cache" -mmin +60 2>/dev/null)" ] && level=$(read_level)

if [ -z "$level" ]; then
  swayosd-client --custom-icon=display-brightness-symbolic --custom-message="DDC read failed"
  exit 1
fi

if [ "$1" = up ]; then
  level=$((level + step))
  [ "$level" -gt 100 ] && level=100
else
  level=$((level - step))
  [ "$level" -lt 0 ] && level=0
fi
echo "$level" >"$cache"

# Parallel ddcutil writers have no ordering, so a slow older write can land last
# and leave the panel behind the cache. One writer pushes the newest value; a
# failed write drops the cache so the next press re-reads the monitor.
(
  flock -n 9 || exit 0
  while :; do
    want=$(cat "$cache" 2>/dev/null) || break
    ddcutil --sleep-multiplier=0.5 setvcp 10 "$want" >/dev/null 2>&1 || rm -f "$cache"
    [ "$(cat "$cache" 2>/dev/null)" = "$want" ] && break
  done
) 9>>"$cache.lock" &

swayosd-client --custom-progress="$(awk -v v="$level" 'BEGIN { printf "%.2f", v / 100 }')" \
  --custom-icon=display-brightness-symbolic
