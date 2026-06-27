#!/bin/sh
# Toggle mic mute with swayosd notification
set -eu

pactl set-source-mute @DEFAULT_SOURCE@ toggle
sleep 0.05
MUTED=$(pactl get-source-mute @DEFAULT_SOURCE@ | grep -qi 'yes' && echo 1 || echo 0)

if [ "$MUTED" = "1" ]; then
    swayosd-client --custom-icon=microphone-sensitivity-muted --custom-message="Mic Muted"
else
    swayosd-client --custom-icon=audio-input-microphone --custom-message="Mic Unmuted"
fi
