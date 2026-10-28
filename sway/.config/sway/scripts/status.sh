#!/bin/bash
# Sway status bar. Sections: [REC] │ [MEDIA] │ [HARDWARE] │ [PERIPHERALS] │ [CLOCK]

TEMP_CACHE=/tmp/sway-cpu-temp
NP_CACHE=/tmp/sway-nowplaying
WIFI_CACHE=/tmp/sway-wifi
VOL_CACHE=/tmp/sway-vol
MIC_CACHE=/tmp/sway-mic-mute
UPDATES_CACHE=/tmp/sway-updates
REC_START=/tmp/sway-rec-start

# fresh <file> <seconds>
fresh() {
  [ -f "$1" ] || return 1
  local age=$(( $(date +%s) - $(stat -c %Y "$1" 2>/dev/null || echo 0) ))
  [ "$age" -lt "$2" ]
}

while true; do
  # Recording timer
  rec_str=""
  sleep_for=3
  if pgrep -x wf-recorder >/dev/null; then
    sleep_for=1
    now=$(date +%s)
    start=$(cat "$REC_START" 2>/dev/null || echo "$now")
    elapsed=$((now - start))
    printf -v rec_str 'REC %02d:%02d' $((elapsed / 60)) $((elapsed % 60))
  fi

  # CPU temperature
  if fresh "$TEMP_CACHE" 30; then
    temp_str=$(cat "$TEMP_CACHE")
  else
    raw=$(head -n1 /sys/class/thermal/thermal_zone*/temp 2>/dev/null || echo 0)
    temp_str="󰔏 $((raw / 1000))°C"
    echo "$temp_str" > "$TEMP_CACHE"
  fi

  # RAM
  ram_str=$(free -h | awk '/^Mem:/ { used=$3; sub(/i$/, "", used); printf "󰍛 %s", used }')

  # Package updates (1h cache, refreshed in the background)
  if fresh "$UPDATES_CACHE" 3600; then
    updates=$(cat "$UPDATES_CACHE")
  else
    updates=$(cat "$UPDATES_CACHE" 2>/dev/null || echo 0)
    if [ ! -f "$UPDATES_CACHE.lock" ]; then
      : > "$UPDATES_CACHE.lock"
      (checkupdates 2>/dev/null | wc -l > "$UPDATES_CACHE"; rm -f "$UPDATES_CACHE.lock") &
    fi
  fi

  sys_str="${temp_str} · ${ram_str}"
  [ "$updates" -gt 0 ] && sys_str="${sys_str} · 󰏗 ${updates}"

  # Now playing
  if fresh "$NP_CACHE" 5; then
    np=$(cat "$NP_CACHE")
  else
    np=$(timeout 1.5 playerctl metadata --format '󰎆 {{artist}} - {{title}}' 2>/dev/null | head -c 42)
    echo "$np" > "$NP_CACHE"
  fi

  # WiFi
  if fresh "$WIFI_CACHE" 20; then
    wifi=$(cat "$WIFI_CACHE")
  else
    if nmcli -t -f active,ssid dev wifi 2>/dev/null | grep -q '^yes'; then
      wifi="󰖩"
    else
      wifi="󰖪"
    fi
    echo "$wifi" > "$WIFI_CACHE"
  fi

  # Output volume
  if fresh "$VOL_CACHE" 5; then
    vol_str=$(cat "$VOL_CACHE")
  else
    if pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -q 'Mute: yes'; then
      vol_str="󰖁"
    else
      level=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oP '\d+%' | head -n1 | tr -d '%')
      level=${level:-0}
      if [ "$level" -eq 0 ]; then
        vol_str="󰖁"
      elif [ "$level" -lt 34 ]; then
        vol_str="󰕿 ${level}%"
      elif [ "$level" -lt 67 ]; then
        vol_str="󰖀 ${level}%"
      else
        vol_str="󰕾 ${level}%"
      fi
    fi
    echo "$vol_str" > "$VOL_CACHE"
  fi

  # Microphone mute, shown only when muted
  mic_str=""
  if fresh "$MIC_CACHE" 3; then
    [ "$(cat "$MIC_CACHE")" = "1" ] && mic_str=" · 󰍭"
  else
    if pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | grep -qi 'yes'; then
      mic_str=" · 󰍭"
      echo "1" > "$MIC_CACHE"
    else
      echo "0" > "$MIC_CACHE"
    fi
  fi

  # Battery
  battery=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo 0)
  charge=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo '')
  if [ "$charge" = "Charging" ]; then
    bat_icon="󰂄"
  elif [ "$battery" -ge 90 ]; then
    bat_icon="󰁹"
  elif [ "$battery" -ge 70 ]; then
    bat_icon="󰂀"
  elif [ "$battery" -ge 50 ]; then
    bat_icon="󰁾"
  elif [ "$battery" -ge 30 ]; then
    bat_icon="󰁼"
  elif [ "$battery" -ge 15 ]; then
    bat_icon="󰁺"
  else
    bat_icon="󰂃"
  fi

  # Keyboard backlight
  kbd_str=""
  kbd=$(cat /sys/class/leds/tpacpi::kbd_backlight/brightness 2>/dev/null || echo 0)
  [ "$kbd" -gt 0 ] && kbd_str=" · 󰌌"

  peri_str="${wifi} · ${vol_str}${mic_str} · ${bat_icon} ${battery}%${kbd_str}"
  clock_str="󰃭 $(date +'%d %b · %H:%M')"

  out=""
  [ -n "$rec_str" ] && out="${rec_str}  │  "
  [ -n "$np" ] && out="${out}${np}  │  "
  echo "${out}${sys_str}  │  ${peri_str}  │  ${clock_str}"

  sleep "$sleep_for"
done
