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

# put <file> <value>: atomic write, so a reader never sees a half-written cache.
put() {
  printf '%s\n' "$2" > "$1.$$" && mv -f "$1.$$" "$1"
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

  # CPU temperature: search for common package/core sensors, fallback to zone0
  temp_str=$(cat "$TEMP_CACHE" 2>/dev/null)
  if ! fresh "$TEMP_CACHE" 30 || [ -z "$temp_str" ]; then
    raw=""
    for z in /sys/class/thermal/thermal_zone*; do
      type=$(cat "$z/type" 2>/dev/null || true)
      case "$type" in
        x86_pkg_temp | cpu* | k10temp | coretemp)
          raw=$(cat "$z/temp" 2>/dev/null || true)
          [ -n "$raw" ] && break
          ;;
      esac
    done
    [ -z "$raw" ] && raw=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0)
    raw=${raw:-0}
    temp_str="󰔏 $((raw / 1000))°C"
    put "$TEMP_CACHE" "$temp_str"
  fi

  # RAM
  ram_str=$(free -h | awk '/^Mem:/ { used=$3; sub(/i$/, "", used); printf "󰍛 %s", used }')

  # Package updates (1h cache, refreshed in the background)
  updates=$(cat "$UPDATES_CACHE" 2>/dev/null)
  updates=${updates:-0}
  if ! fresh "$UPDATES_CACHE" 3600; then
    # flock releases on its own, so a killed checkupdates cannot wedge the timer.
    (
      flock -n 9 || exit 0
      put "$UPDATES_CACHE" "$(checkupdates 2>/dev/null | wc -l)"
    ) 9>>"$UPDATES_CACHE.lock" &
  fi

  sys_str="${temp_str} · ${ram_str}"
  [ "$updates" -gt 0 ] && sys_str="${sys_str} · 󰏗 ${updates}"

  # Now playing
  if fresh "$NP_CACHE" 5; then
    np=$(cat "$NP_CACHE")
  else
    np=$(timeout 1.5 playerctl metadata --format '󰎆 {{artist}} - {{title}}' 2>/dev/null | cut -c1-42)
    put "$NP_CACHE" "$np"
  fi

  # WiFi
  wifi=$(cat "$WIFI_CACHE" 2>/dev/null)
  if ! fresh "$WIFI_CACHE" 20 || [ -z "$wifi" ]; then
    if nmcli -t -f active,ssid dev wifi 2>/dev/null | grep -q '^yes'; then
      wifi="󰖩"
    else
      wifi="󰖪"
    fi
    put "$WIFI_CACHE" "$wifi"
  fi

  # Output volume
  vol_str=$(cat "$VOL_CACHE" 2>/dev/null)
  if ! fresh "$VOL_CACHE" 5 || [ -z "$vol_str" ]; then
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
    put "$VOL_CACHE" "$vol_str"
  fi

  # Microphone mute, shown only when muted
  mic_str=""
  if fresh "$MIC_CACHE" 3; then
    [ "$(cat "$MIC_CACHE")" = "1" ] && mic_str=" · 󰍭"
  else
    if pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | grep -qi 'yes'; then
      mic_str=" · 󰍭"
      put "$MIC_CACHE" 1
    else
      put "$MIC_CACHE" 0
    fi
  fi

  # Battery (detect BAT0, BAT1, or omit cleanly on desktops without batteries)
  bat_str=""
  for b in /sys/class/power_supply/BAT*; do
    if [ -d "$b" ]; then
      battery=$(cat "$b/capacity" 2>/dev/null || echo 0)
      charge=$(cat "$b/status" 2>/dev/null || echo '')
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
      bat_str=" · ${bat_icon} ${battery}%"
      break
    fi
  done

  # Keyboard backlight (generic across vendors)
  kbd_str=""
  for d in /sys/class/leds/tpacpi::kbd_backlight/brightness /sys/class/leds/*kbd*backlight*/brightness /sys/class/leds/*::kbd_backlight/brightness; do
    if [ -f "$d" ]; then
      kbd=$(cat "$d" 2>/dev/null || echo 0)
      [ "$kbd" -gt 0 ] && kbd_str=" · 󰌌"
      break
    fi
  done

  peri_str="${wifi} · ${vol_str}${mic_str}${bat_str}${kbd_str}"
  clock_str="󰃭 $(date +'%d %b · %H:%M')"

  out=""
  [ -n "$rec_str" ] && out="${rec_str}  │  "
  [ -n "$np" ] && out="${out}${np}  │  "
  echo "${out}${sys_str}  │  ${peri_str}  │  ${clock_str}"

  sleep "$sleep_for"
done
