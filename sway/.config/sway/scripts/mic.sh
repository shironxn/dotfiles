#!/bin/sh
# Toggle every capture source. Drives the ThinkPad microphone LED through
# snd-ctl-led, so the LED follows mute state without extra wiring.
set -eu

# Fallback is per-uid: a shared /tmp/sway could be pre-created as a symlink by
# another user, and every written path would follow it.
RT="${XDG_RUNTIME_DIR:-/tmp}/sway-$(id -u)"
mkdir -p "$RT"

if pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | grep -qi 'yes'; then
  mute=0
  icon=audio-input-microphone-symbolic
  msg=On
else
  mute=1
  icon=microphone-disabled-symbolic
  msg=Muted
fi

# Monitor sources are loopbacks, not capture devices; muting them is noise.
failed=0
for src in $(pactl list sources short | awk '!/\.monitor/ {print $1}'); do
  pactl set-source-mute "$src" "$mute" || failed=1
  [ "$mute" -eq 0 ] && { pactl set-source-volume "$src" 100% || failed=1; }
done

# Cache only what actually landed, so the bar never reports a state the mixer
# rejected.
if [ "$failed" -eq 0 ]; then
  echo "$mute" >"$RT/mic-mute"
else
  rm -f "$RT/mic-mute"
  icon=microphone-disabled-symbolic
  msg="Mute failed"
fi

swayosd-client --custom-icon="$icon" --custom-message="$msg" || true
