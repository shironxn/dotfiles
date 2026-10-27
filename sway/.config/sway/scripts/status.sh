#!/bin/bash
# Sway status bar — minimal & lightweight
kill $(pgrep -f /status\.sh | grep -v $$) 2>/dev/null

# ── Cache files ──
TEMP_CACHE=/tmp/sway-cpu-temp
VOL_CACHE=/tmp/sway-vol
UPDATES_CACHE=/tmp/sway-updates
NP_CACHE=/tmp/sway-nowplaying

while true; do
  # ── System ──
  # CPU temperature (cache 2m)
  if [ -f "$TEMP_CACHE" ] && [ "$(find "$TEMP_CACHE" -mmin +2)" = "" ]; then
    temp_str=$(cat "$TEMP_CACHE")
  else
    temp_raw=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | head -1 || echo 0)
    temp_c=$((temp_raw / 1000))
    if [ "$temp_c" -ge 80 ]; then icon="󰈸"
    elif [ "$temp_c" -ge 60 ]; then icon="󰈐"
    else icon="󱃂"; fi
    temp_str="${icon} ${temp_c}°C"
    echo "$temp_str" > "$TEMP_CACHE"
  fi

  # RAM usage
  ram_str=$(free -h | awk '/^Mem:/ {
    used=$3; sub(/i$/,"",used); printf "󰍛 %s", used
  }')

  # Package updates (cache 1h — refresh di background, bar nggak nunggu)
  if [ -f "$UPDATES_CACHE" ] && [ "$(find "$UPDATES_CACHE" -mmin +60)" = "" ]; then
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
  # Now Playing (cache 10s)
  if [ -f "$NP_CACHE" ] && [ $(( $(date +%s) - $(stat -c %Y "$NP_CACHE" 2>/dev/null) )) -lt 10 ]; then
    np=$(cat "$NP_CACHE")
  else
    np=$(timeout 2 playerctl metadata --format '󰎆 {{artist}} - {{title}}' 2>/dev/null | head -c 50)
    echo "$np" > "$NP_CACHE"
  fi

  # ── Peripherals ──
  # Volume (cache 10s)
  if [ -f "$VOL_CACHE" ] && [ $(( $(date +%s) - $(stat -c %Y "$VOL_CACHE" 2>/dev/null) )) -lt 10 ]; then
    vol=$(cat "$VOL_CACHE")
  else
    if pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -q "Mute: yes"; then
      vol="MUTED"
    else
      vol=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oP '\d+%' | head -1)
    fi
    echo "$vol" > "$VOL_CACHE"
  fi

  # WiFi — icon doang (cache 30s — nmcli berat)
  WIFI_CACHE=/tmp/sway-wifi
  if [ -f "$WIFI_CACHE" ] && [ $(( $(date +%s) - $(stat -c %Y "$WIFI_CACHE" 2>/dev/null) )) -lt 30 ]; then
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

  # Date
  date_str=$(date +'%d %b %H:%M')

  # ── Build status line ──
  # Layout: [CPU] [RAM] [Updates] | [Now Playing] | [WiFi] [Vol] [Bat] [KBD] [Date]
  left=""

  # Left section: system health
  left="${left}${temp_str}"
  left="${left}  ${ram_str}"
  [ "$updates" -gt 0 ] && left="${left}  󰏗 ${updates}"

  # Middle: now playing (conditional)
  middle=""
  [ -n "$np" ] && middle="${np}"

  # Right section: daily status
  right="${wifi_icon}  󰕾 ${vol}  ${bat_icon} ${battery}%"
  [ -n "$kbd_str" ] && right="${right}  ${kbd_str}"
  right="${right}  󰃭 ${date_str}"

  # Combine
  if [ -n "$middle" ]; then
    echo "${left}  |  ${middle}  |  ${right}"
  else
    echo "${left}  |  ${right}"
  fi

  sleep 10
done
