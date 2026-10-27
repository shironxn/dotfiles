#!/bin/sh
# Toggle mic mute for all audio sources + sync ThinkPad LED and OSD
set -eu

# Check current mute state of default source (if muted, we will unmute; otherwise mute)
if pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | grep -qi 'yes'; then
    NEW_STATE=0
else
    NEW_STATE=1
fi

# Mute/unmute all capture sources (excluding monitor outputs)
# This keeps external mics (USB webcam/headset) and internal mic (card0 / ALC257) in sync,
# which triggers the ThinkPad hardware mic mute LED via snd-ctl-led.
pactl list sources short | grep -v '\.monitor' | awk '{print $1}' | while read -r src; do
    pactl set-source-mute "$src" "$NEW_STATE" || true
    if [ "$NEW_STATE" -eq 0 ]; then
        pactl set-source-volume "$src" 100% || true
    fi
done

if [ "$NEW_STATE" -eq 1 ]; then
    swayosd-client --custom-icon=microphone-disabled-symbolic --custom-message="Muted" || true
else
    swayosd-client --custom-icon=audio-input-microphone-symbolic --custom-message="On" || true
fi
