#!/bin/sh
# Smart brightness: adjust laptop (eDP-1) or external monitor (HDMI-A-2)
# based on which output is currently focused.

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
        CACHE=~/.cache/brightness-hdmi
        # init cache from hardware if missing; invalidate if >1h old
        if [ ! -f "$CACHE" ] || [ "$(find "$CACHE" -mmin +60)" ]; then
            sg i2c -c "ddcutil -d 1 getvcp 10 --brief" 2>/dev/null | awk '{print $4}' > "$CACHE"
        fi
        CURRENT=$(cat "$CACHE")
        MAX=100
        case "$1" in
            up)   NEW=$((CURRENT + STEP))
                  [ "$NEW" -gt "$MAX" ] && NEW=$MAX ;;
            down) NEW=$((CURRENT - STEP))
                  [ "$NEW" -lt 0 ] && NEW=0 ;;
        esac
        echo "$NEW" > "$CACHE"
        # background I2C write so script returns instantly
        sg i2c -c "ddcutil --sleep-multiplier=0.5 -d 1 setvcp 10 $NEW" &>/dev/null &
        swayosd-client --custom-progress="$(python3 -c "print($NEW / 100)")" \
                       --custom-icon=display-brightness
        ;;
esac
