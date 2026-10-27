#!/bin/sh
# Smart brightness: onboard (eDP-1) via swayosd, external monitor via ddcutil
# Usage: brightness-switch.sh up|down [step]

set -eu

STEP="${2:-5}"
FOCUSED=$(swaymsg -t get_outputs --raw | python3 -c "
import sys, json
outs = json.load(sys.stdin)
print(next(o['name'] for o in outs if o['focused']))
")

case "$FOCUSED" in
    eDP-1)
        case "$1" in
            up)   swayosd-client --brightness raise --device intel_backlight ;;
            down) swayosd-client --brightness lower --device intel_backlight ;;
        esac
        ;;
    HDMI-A-2)
        if ! command -v ddcutil >/dev/null; then
            swayosd-client --custom-icon=display-brightness-symbolic --custom-message="ddcutil not found"
            exit 1
        fi
        CACHE=~/.cache/brightness-hdmi
        # Baca nilai real dari monitor kalo cache missing / basi (>60 mnt) / invalid
        if [ ! -f "$CACHE" ] || [ -n "$(find "$CACHE" -mmin +60 2>/dev/null)" ] || ! grep -qE '^[0-9]+$' "$CACHE" 2>/dev/null; then
            ddcutil -d 1 getvcp 10 --brief 2>/dev/null | awk '{print $4}' > "$CACHE"
        fi
        CURRENT=$(cat "$CACHE" 2>/dev/null || echo "")
        case "$CURRENT" in
            ''|*[!0-9]*)
                CURRENT=$(ddcutil -d 1 getvcp 10 --brief 2>/dev/null | awk '{print $4}')
                echo "$CURRENT" > "$CACHE"
                ;;
        esac
        if [ -z "$CURRENT" ]; then
            swayosd-client --custom-icon=display-brightness-symbolic --custom-message="ddcutil read failed"
            exit 1
        fi
        MAX=100
        case "$1" in
            up)   NEW=$((CURRENT + STEP))
                  [ "$NEW" -gt "$MAX" ] && NEW=$MAX ;;
            down) NEW=$((CURRENT - STEP))
                  [ "$NEW" -lt 0 ] && NEW=0 ;;
        esac
        echo "$NEW" > "$CACHE"
        # Direct call — udev uaccess rule udah kasih rw ke /dev/i2c-*, nggak perlu wrapper `sg`
        ddcutil --sleep-multiplier=0.5 -d 1 setvcp 10 "$NEW" &>/dev/null &
        swayosd-client --custom-progress="$(python3 -c "print($NEW / 100)")" \
                       --custom-icon=display-brightness-symbolic
        ;;
esac
