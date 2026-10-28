#!/bin/bash
# Sway status bar — minimal, elegant & lightweight

# ── Cache files ──
TEMP_CACHE=/tmp/sway-cpu-temp
VOL_CACHE=/tmp/sway-vol
UPDATES_CACHE=/tmp/sway-updates
NP_CACHE=/tmp/sway-nowplaying
WIFI_CACHE=/tmp/sway-wifi

while true; do
  # ── 1. Recording Alert with Live Timer ──
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
    rec_str="REC ${rec_timer}"
  fi

  # ── 2. System Hardware (CPU temp & RAM) ──
  # CPU temperature (cached for 30s)
  if [ -f "$TEMP_CACHE" ] && [ $(( $(date +%s) - $(stat -c %Y "$TEMP_CACHE" 2>/dev/null) )) -lt 30 ]; then
    temp_str=$(cat "$TEMP_CACHE")
  else
    temp_raw=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | head -1 || echo 0)
    temp_c=$((temp_raw / 1000))
    temp_str="󰔏 ${temp_c}°C"
    echo "$temp_str" > "$TEMP_CACHE"
  fi

  # RAM usage
  ram_str=$(free -h | awk '/^Mem:/ {
    used=$3; sub(/i$/,"",used); printf "󰍛 %s", used
  }')

  # Package updates (cached for 1h, refreshes in background)
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

  sys_str="${temp_str} · ${ram_str}"
  [ "$updates" -gt 0 ] && sys_str="${sys_str} · 󰏗 ${updates}"

  # ── 3. Media (Now Playing, cached for 5s) ──
  if [ -f "$NP_CACHE" ] && [ $(( $(date +%s) - $(stat -c %Y "$NP_CACHE" 2>/dev/null) )) -lt 5 ]; then
    np=$(cat "$NP_CACHE")
  else
    np=$(timeout 1.5 playerctl metadata --format '󰎆 {{artist}} - {{title}}' 2>/dev/null | head -c 42)
    echo "$np" > "$NP_CACHE"
  fi

  # ── 4. Peripherals & Network ──
  # WiFi (cached for 20s)
  if [ -f "$WIFI_CACHE" ] && [ $(( $(date +%s) - $(stat -c %Y "$WIFI_CACHE" 2>/dev/null) )) -lt 20 ]; then
    wifi_icon=$(cat "$WIFI_CACHE")
  else
    wifi_connected=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep -c "^yes")
    [ "$wifi_connected" -gt 0 ] && wifi_icon="󰖩" || wifi_icon="󰖪"
    echo "$wifi_icon" > "$WIFI_CACHE"
  fi

  # Volume (cached for 5s, dynamic volume icon)
  if [ -f "$VOL_CACHE" ] && [ $(( $(date +%s) - $(stat -c %Y "$VOL_CACHE" 2>/dev/null) )) -lt 5 ]; then
    vol_str=$(cat "$VOL_CACHE")
  else
    if pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -q "Mute: yes"; then
      vol_str="󰖁 MUTE"
    else
      vol_num=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oP '\d+%' | head -1 | tr -d '%')
      vol_num=${vol_num:-0}
      if [ "$vol_num" -eq 0 ]; then
        vol_str="󰖁 0%"
      elif [ "$vol_num" -lt 34 ]; then
        vol_str="󰕿 ${vol_num}%"
      elif [ "$vol_num" -lt 67 ]; then
        vol_str="󰖀 ${vol_num}%"
      else
        vol_str="󰕾 ${vol_num}%"
      fi
    fi
    echo "$vol_str" > "$VOL_CACHE"
  fi

  # Microphone Mute (contextual: only shown when muted, cached 3s)
  mic_str=""
  if [ -f "/tmp/sway-mic-mute" ] && [ $(( $(date +%s) - $(stat -c %Y "/tmp/sway-mic-mute" 2>/dev/null) )) -lt 3 ]; then
    [ "$(cat /tmp/sway-mic-mute 2>/dev/null)" = "1" ] && mic_str=" · 󰍭"
  else
    if pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | grep -qi 'yes'; then
      mic_str=" · 󰍭"
      echo "1" > /tmp/sway-mic-mute
    else
      echo "0" > /tmp/sway-mic-mute
    fi
  fi

  # Battery (dynamic tiered icon & charging status)
  battery=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo 0)
  charge=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo "?")
  case "$charge" in
    Charging) bat_icon="󰂄" ;;
    *)
      if [ "$battery" -ge 90 ]; then bat_icon="󰁹"
      elif [ "$battery" -ge 70 ]; then bat_icon="󰂀"
      elif [ "$battery" -ge 50 ]; then bat_icon="󰁾"
      elif [ "$battery" -ge 30 ]; then bat_icon="󰁼"
      elif [ "$battery" -ge 15 ]; then bat_icon="󰁺"
      else bat_icon="󰂃"; fi
      ;;
  esac
  bat_str="${bat_icon} ${battery}%"

  # Keyboard backlight (optional indicator)
  kbd_val=$(cat /sys/class/leds/tpacpi::kbd_backlight/brightness 2>/dev/null || echo 0)
  [ "$kbd_val" -gt 0 ] && kbd_str=" · 󰌌" || kbd_str=""

  peri_str="${wifi_icon} · ${vol_str}${mic_str} · ${bat_str}${kbd_str}"

  # ── 5. Date & Time ──
  clock_str="󰃭 $(date +'%d %b · %H:%M')"

  # ── 6. Assemble Final Bar ──
  # Layout order: [REC] │ [MEDIA] │ [SYSTEM] │ [PERIPHERALS] │ [DATE/TIME]
  # Transient items (REC & MEDIA) expand to the left/center, keeping
  # hardware, peripherals, and clock rock-solid on the right.
  out=""
  [ -n "$rec_str" ] && out="${out}${rec_str}  │  "
  [ -n "$np" ]      && out="${out}${np}  │  "
  out="${out}${sys_str}  │  ${peri_str}  │  ${clock_str}"

  echo "$out"

  # 1s refresh when recording for live timer, otherwise 3s
  if [ "$is_recording" -eq 1 ]; then
    sleep 1
  else
    sleep 3
  fi
done
