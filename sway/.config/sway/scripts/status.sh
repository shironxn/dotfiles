#!/bin/bash
# Sway status bar — minimal, elegant & lightweight
kill $(pgrep -f /status\.sh | grep -v $$) 2>/dev/null

# ── Cache files ──
TEMP_CACHE=/tmp/sway-cpu-temp
VOL_CACHE=/tmp/sway-vol
UPDATES_CACHE=/tmp/sway-updates
NP_CACHE=/tmp/sway-nowplaying
WIFI_CACHE=/tmp/sway-wifi

while true; do
  # ── Recording status indicator with real-time timer ──
  rec_str=""
  is_recording=0
  if pgrep -x wf-recorder >/dev/null; then
    is_recording=1
    rec_now=$(date +%s)
    rec_start=$(cat /tmp/sway-rec-start 2>/dev/null || echo "$rec_now")
    rec_elapsed=$((rec_now - rec_start))
    rec_min=$((rec_elapsed / 60))
    rec_sec=$((rec_elapsed % 60))
    rec_timer=$(printf "%02d:%02d" "$rec_min" "$rec_sec")
    rec_str="󰑃 REC ${rec_timer}  │  "
  fi

  # ── System Health ──
  # CPU temperature (cached for 30s)
  if [ -f "$TEMP_CACHE" ] && [ $(( $(date +%s) - $(stat -c %Y "$TEMP_CACHE" 2>/dev/null) )) -lt 30 ]; then
    temp_str=$(cat "$TEMP_CACHE")
  else
    temp_raw=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | head -1 || echo 0)
    temp_c=$((temp_raw / 1000))
    if [ "$temp_c" -ge 80 ]; then icon="󰈸"
    elif [ "$temp_c" -ge 65 ]; then icon="󰈐"
    else icon="󱃂"; fi
    temp_str="${icon} ${temp_c}°C"
    echo "$temp_str" > "$TEMP_CACHE"
  fi

  # RAM usage
  ram_str=$(free -h | awk '/^Mem:/ {
    used=$3; sub(/i$/,"",used); printf "󰍛 %s", used
  }')

  # Package updates (cached for 1h, refreshes in background without blocking bar)
  if [ -f "$UPDATES_CACHE" ] && [ $(( $(date +%s) - $(stat -c %Y "$UPDATES_CACHE" 2>/dev/null) )) -lt 3600 ]; then
    updates=$(cat "$UPDATES_CACHE")
  else
    updates=$(cat "$UPDATES_CACHE" 2>/dev/null || echo 0)
    updates=${updates:-0}
    if [ ! -f "$UPDATES_CACHE.lock" ]; then
      : > "$UPDATES_CACHE.lock"
      ( count=$(checkupdates 2>/dev/null | wc -l); echo "$count" > "$UPDATES_CACHE"; rm -f "$UPDATES_CACHE.lock" ) &
    fi
  fi

  # ── Media ──
  # Now Playing (cached for 5s)
  if [ -f "$NP_CACHE" ] && [ $(( $(date +%s) - $(stat -c %Y "$NP_CACHE" 2>/dev/null) )) -lt 5 ]; then
    np=$(cat "$NP_CACHE")
  else
    np=$(timeout 1.5 playerctl metadata --format '󰎆 {{artist}} - {{title}}' 2>/dev/null | head -c 45)
    echo "$np" > "$NP_CACHE"
  fi

  # ── Peripherals & Network ──
  # Volume (cached for 5s)
  if [ -f "$VOL_CACHE" ] && [ $(( $(date +%s) - $(stat -c %Y "$VOL_CACHE" 2>/dev/null) )) -lt 5 ]; then
    vol=$(cat "$VOL_CACHE")
  else
    if pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -q "Mute: yes"; then
      vol="󰖁 MUTE"
    else
      vol_val=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oP '\d+%' | head -1)
      vol="󰕾 ${vol_val:-0%}"
    fi
    echo "$vol" > "$VOL_CACHE"
  fi

  # WiFi (cached for 20s)
  if [ -f "$WIFI_CACHE" ] && [ $(( $(date +%s) - $(stat -c %Y "$WIFI_CACHE" 2>/dev/null) )) -lt 20 ]; then
    wifi_icon=$(cat "$WIFI_CACHE")
  else
    wifi_connected=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep -c "^yes")
    [ "$wifi_connected" -gt 0 ] && wifi_icon="󰖩" || wifi_icon="󰖪"
    echo "$wifi_icon" > "$WIFI_CACHE"
  fi

  # Battery
  battery=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo "?")
  charge=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo "?")
  case "$charge" in
    Charging) bat_icon="󰂄" ;;
    Full)     bat_icon="󰁹" ;;
    *)        bat_icon="󰁿" ;;
  esac

  # Keyboard backlight
  kbd_val=$(cat /sys/class/leds/tpacpi::kbd_backlight/brightness 2>/dev/null || echo 0)
  [ "$kbd_val" -gt 0 ] && kbd_str="󰌌" || kbd_str=""

  # Date & Time (clean monospace spacing)
  date_str=$(date +'%d %b  %H:%M')

  # ── Assemble Status Layout ──
  # Sections: [System] │ [Now Playing] │ [Peripherals] │ [Date/Time]
  
  sys="${temp_str}  ${ram_str}"
  [ "$updates" -gt 0 ] && sys="${sys}  󰏗 ${updates}"

  peri="${wifi_icon}  ${vol}  ${bat_icon} ${battery}%"
  [ -n "$kbd_str" ] && peri="${peri}  ${kbd_str}"

  clock="󰃭 ${date_str}"

  if [ -n "$np" ]; then
    echo "${rec_str}${sys}  │  ${np}  │  ${peri}  │  ${clock}"
  else
    echo "${rec_str}${sys}  │  ${peri}  │  ${clock}"
  fi

  # Refresh 1s while recording so timer updates smoothly, otherwise 3s
  if [ "$is_recording" -eq 1 ]; then
    sleep 1
  else
    sleep 3
  fi
done
