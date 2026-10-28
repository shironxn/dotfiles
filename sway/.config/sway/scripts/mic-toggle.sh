#!/bin/sh
# Toggle every capture source, which also drives the ThinkPad microphone LED
# through snd-ctl-led. Monitor sources are skipped.
set -eu

if pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | grep -qi 'yes'; then
    NEW_STATE=0
else
    NEW_STATE=1
fi

pactl list sources short | grep -v '\.monitor' | awk '{print $1}' | while read -r src; do
    pactl set-source-mute "$src" "$NEW_STATE" || true
    if [ "$NEW_STATE" -eq 0 ]; then
        pactl set-source-volume "$src" 100% || true
    fi
done

if [ "$NEW_STATE" -eq 1 ]; then
    echo "1" > /tmp/sway-mic-mute
    swayosd-client --custom-icon=microphone-disabled-symbolic --custom-message="Muted" || true
else
    echo "0" > /tmp/sway-mic-mute
    swayosd-client --custom-icon=audio-input-microphone-symbolic --custom-message="On" || true
fi
