#!/bin/sh
# Sway bar status line: [REC] │ [MEDIA] │ [HARDWARE] │ [PERIPHERALS] │ [CLOCK]
set -u # -e omitted: the loop must survive failed probes

# Fallback is per-uid: a shared /tmp/sway could be pre-created as a symlink by
# another user, and every written path would follow it.
RT="${XDG_RUNTIME_DIR:-/tmp}/sway-$(id -u)"
mkdir -p "$RT"
UPDATES_CACHE="$RT/updates"

# fresh <file> <seconds>
fresh() {
  [ -f "$1" ] || return 1
  [ "$(($(date +%s) - $(stat -c %Y "$1" 2>/dev/null || echo 0)))" -lt "$2" ]
}

# put <file> <value>: rename is atomic, so a reader never sees a partial write.
put() {
  printf '%s\n' "$2" >"$1.$$" && mv -f "$1.$$" "$1"
}

# cached <file> <seconds> <command...>: print the cache, or recompute and store it.
cached() {
  file=$1
  if fresh "$file" "$2"; then
    cat "$file"
    return 0
  fi
  shift 2
  value=$("$@" 2>/dev/null)
  put "$file" "$value"
  printf '%s' "$value"
}

cpu_temp() {
  raw=""
  for z in /sys/class/thermal/thermal_zone*; do
    case "$(cat "$z/type" 2>/dev/null)" in
    x86_pkg_temp | cpu* | k10temp | coretemp)
      raw=$(cat "$z/temp" 2>/dev/null) && [ -n "$raw" ] && break
      ;;
    esac
  done
  [ -n "$raw" ] || raw=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0)
  printf '󰔏 %s°C' "$((${raw:-0} / 1000))"
}

now_playing() {
  # Metadata outlives playback, so a stopped player would keep its last track
  # on the bar indefinitely.
  [ "$(timeout 1.5 playerctl status 2>/dev/null)" = "Playing" ] || return 0
  timeout 1.5 playerctl metadata --format '󰎆 {{artist}} - {{title}}' 2>/dev/null | cut -c1-42
}

wifi_icon() {
  if nmcli -t -f active,ssid dev wifi 2>/dev/null | grep -q '^yes'; then
    printf '󰖩'
  else
    printf '󰖪'
  fi
}

volume() {
  if pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -q 'Mute: yes'; then
    printf '󰖁'
    return 0
  fi
  level=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -o '[0-9]*%' | head -n1 | tr -d '%')
  level=${level:-0}
  if [ "$level" -eq 0 ]; then
    printf '󰖁'
  elif [ "$level" -lt 34 ]; then
    printf '󰕿 %s%%' "$level"
  elif [ "$level" -lt 67 ]; then
    printf '󰖀 %s%%' "$level"
  else
    printf '󰕾 %s%%' "$level"
  fi
}

mic_flag() {
  if pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | grep -qi 'yes'; then
    printf 1
  else
    printf 0
  fi
}

battery() {
  for b in /sys/class/power_supply/BAT*; do
    [ -d "$b" ] || continue
    capacity=$(cat "$b/capacity" 2>/dev/null || echo 0)
    if [ "$(cat "$b/status" 2>/dev/null)" = Charging ]; then
      icon=󰂄
    elif [ "$capacity" -ge 90 ]; then
      icon=󰁹
    elif [ "$capacity" -ge 70 ]; then
      icon=󰂀
    elif [ "$capacity" -ge 50 ]; then
      icon=󰁾
    elif [ "$capacity" -ge 30 ]; then
      icon=󰁼
    elif [ "$capacity" -ge 15 ]; then
      icon=󰁺
    else
      icon=󰂃
    fi
    printf ' · %s %s%%' "$icon" "$capacity"
    return 0
  done
}

kbd_flag() {
  for d in /sys/class/leds/tpacpi::kbd_backlight/brightness \
    /sys/class/leds/*kbd*backlight*/brightness \
    /sys/class/leds/*::kbd_backlight/brightness; do
    [ -f "$d" ] || continue
    [ "$(cat "$d" 2>/dev/null || echo 0)" -gt 0 ] && printf ' · 󰌌'
    return 0
  done
}

# Package updates cost a full repo query, so they run detached with a 1h cache
# and are refreshed early whenever pacman's own databases change.
refresh_updates() {
  [ -f /var/lib/pacman/db.lck ] && return 0
  pacman_time=$(stat -c %Y /var/lib/pacman/local /var/lib/pacman/sync 2>/dev/null | sort -nr | head -n1)
  cache_time=$(stat -c %Y "$UPDATES_CACHE" 2>/dev/null || echo 0)
  fresh "$UPDATES_CACHE" 3600 && [ "${pacman_time:-0}" -le "${cache_time:-0}" ] && return 0
  (
    flock -n 9 || exit 0
    out=$(checkupdates 2>/dev/null)
    case $? in
    0) put "$UPDATES_CACHE" "$(printf '%s\n' "$out" | grep -c .)" ;;
    2) put "$UPDATES_CACHE" 0 ;;
    *) touch "$UPDATES_CACHE" ;;
    esac
  ) 9>>"$UPDATES_CACHE.lock" &
}

while :; do
  sleep_for=3

  rec=""
  if pgrep -x wf-recorder >/dev/null; then
    sleep_for=1
    # Read the age from the process itself. A start-time file would break the
    # moment the bar and record.sh disagree on a path, and the counter would
    # sit at 00:00 for the whole recording.
    elapsed=$(ps -o etimes= -p "$(pgrep -x wf-recorder | head -n1)" 2>/dev/null | tr -d ' ')
    case "$elapsed" in '' | *[!0-9]*) elapsed=0 ;; esac
    if [ "$elapsed" -ge 3600 ]; then
      rec=$(printf 'REC %d:%02d:%02d' $((elapsed / 3600)) $((elapsed / 60 % 60)) $((elapsed % 60)))
    else
      rec=$(printf 'REC %02d:%02d' $((elapsed / 60)) $((elapsed % 60)))
    fi
  fi

  refresh_updates
  updates=$(cat "$UPDATES_CACHE" 2>/dev/null || echo 0)
  case "$updates" in '' | *[!0-9]*) updates=0 ;; esac

  temp=$(cached "$RT/cpu-temp" 30 cpu_temp)
  media=$(cached "$RT/nowplaying" 5 now_playing)
  wifi=$(cached "$RT/wifi" 20 wifi_icon)
  vol=$(cached "$RT/vol" 5 volume)

  mic=""
  if fresh "$RT/mic-mute" 3; then
    [ "$(cat "$RT/mic-mute")" = 1 ] && mic=" · 󰍭"
  else
    muted=$(mic_flag)
    put "$RT/mic-mute" "$muted"
    [ "$muted" = 1 ] && mic=" · 󰍭"
  fi

  ram=$(free -h | awk '/^Mem:/ { sub(/i$/, "", $3); printf "󰍛 %s", $3 }')
  hardware="${temp} · ${ram}"
  [ "$updates" -gt 0 ] && hardware="${hardware} · 󰏗 ${updates}"

  peripherals="${wifi} · ${vol}${mic}$(battery)$(kbd_flag)"

  out=""
  [ -n "$rec" ] && out="${rec}  │  "
  [ -n "$media" ] && out="${out}${media}  │  "
  printf '%s%s  │  %s  │  󰃭 %s\n' "$out" "$hardware" "$peripherals" "$(date +'%d %b · %H:%M')"

  sleep "$sleep_for"
done
