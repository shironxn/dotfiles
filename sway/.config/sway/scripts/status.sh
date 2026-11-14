#!/bin/sh
# Sway bar status line: [REC] │ [MEDIA] │ [HARDWARE] │ [PERIPHERALS] │ [CLOCK]
set -u # -e omitted: the loop must survive failed probes

# Per-uid fallback: a shared /tmp/sway can be a symlink planted by another user,
# and every write below would follow it.
RT="${XDG_RUNTIME_DIR:-/tmp}/sway-$(id -u)"
UPDATES_CACHE="$RT/updates"
mkdir -p "$RT"

# put <file> <value>: rename is atomic, so a reader never sees a partial write.
put() {
  printf '%s\n' "$2" >"$1.$$" && mv -f "$1.$$" "$1"
}

# cached <file> <seconds> <command...>: serve the cache, or recompute and store.
cached() {
  file=$1
  if [ -f "$file" ] &&
    [ "$(($(date +%s) - $(stat -c %Y "$file" 2>/dev/null || echo 0)))" -lt "$2" ]; then
    cat "$file"
    return 0
  fi
  shift 2
  value=$("$@" 2>/dev/null)
  put "$file" "$value"
  printf '%s' "$value"
}

# join <separator> <part...>: empty parts drop out, so a missing probe never
# leaves a dangling separator on the bar.
join() {
  sep=$1
  out=""
  shift
  for part in "$@"; do
    [ -n "$part" ] || continue
    out=${out:+$out$sep}$part
  done
  printf '%s' "$out"
}

cpu_temp() {
  raw=""
  for zone in /sys/class/thermal/thermal_zone*; do
    case "$(cat "$zone/type" 2>/dev/null)" in
    x86_pkg_temp | cpu* | k10temp | coretemp)
      raw=$(cat "$zone/temp" 2>/dev/null) && [ -n "$raw" ] && break
      ;;
    esac
  done
  raw=${raw:-$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0)}
  printf '󰔏 %s°C' "$((${raw:-0} / 1000))"
}

now_playing() {
  # Metadata outlives playback, so a stopped player would keep its last track.
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
  level=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null |
    grep -o '[0-9]*%' | head -n1 | tr -d '%')
  level=${level:-0}
  if [ "$level" -eq 0 ] ||
    pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -q 'Mute: yes'; then
    printf '󰖁'
  elif [ "$level" -lt 34 ]; then
    printf '󰕿 %s%%' "$level"
  elif [ "$level" -lt 67 ]; then
    printf '󰖀 %s%%' "$level"
  else
    printf '󰕾 %s%%' "$level"
  fi
}

mic_icon() {
  pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | grep -qi 'yes' && printf '󰍭'
}

# WiFi, volume, muted mic, battery and backlight in one cached string: they are
# cheap, and one cache entry beats four.
peripherals() {
  join " · " "$(wifi_icon)" "$(volume)" "$(mic_icon)" "$(battery)" "$(kbd_flag)"
}

battery() {
  for bat in /sys/class/power_supply/BAT*; do
    [ -d "$bat" ] || continue
    capacity=$(cat "$bat/capacity" 2>/dev/null || echo 0)
    case "$(cat "$bat/status" 2>/dev/null):$capacity" in
    Charging:*) icon=󰂄 ;;
    *)
      icon=󰂃
      [ "$capacity" -ge 15 ] && icon=󰁺
      [ "$capacity" -ge 30 ] && icon=󰁼
      [ "$capacity" -ge 50 ] && icon=󰁾
      [ "$capacity" -ge 70 ] && icon=󰂀
      [ "$capacity" -ge 90 ] && icon=󰁹
      ;;
    esac
    printf '%s %s%%' "$icon" "$capacity"
    return 0
  done
}

kbd_flag() {
  for led in /sys/class/leds/tpacpi::kbd_backlight/brightness \
    /sys/class/leds/*kbd*backlight*/brightness \
    /sys/class/leds/*::kbd_backlight/brightness; do
    [ -f "$led" ] || continue
    [ "$(cat "$led" 2>/dev/null || echo 0)" -gt 0 ] && printf '󰌌'
    return 0
  done
}

# Package updates cost a full repo query: run detached, cache for an hour, and
# re-run early whenever pacman's own databases change.
refresh_updates() {
  [ -f /var/lib/pacman/db.lck ] && return 0
  pacman_time=$(stat -c %Y /var/lib/pacman/local /var/lib/pacman/sync 2>/dev/null |
    sort -nr | head -n1)
  cache_time=$(stat -c %Y "$UPDATES_CACHE" 2>/dev/null || echo 0)
  [ "$(($(date +%s) - cache_time))" -lt 3600 ] &&
    [ "${pacman_time:-0}" -le "$cache_time" ] && return 0
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
  # Subshell-free status check: a pipeline reports head's status, not pgrep's.
  pid=$(pgrep -x wf-recorder | head -n1 || true)
  if [ -n "$pid" ]; then
    sleep_for=1
    # Age comes from the process itself. A start-time file breaks the moment the
    # bar and record.sh disagree on a path, and the counter sticks at 00:00.
    elapsed=$(ps -o etimes= -p "$pid" 2>/dev/null | tr -d ' ')
    case "$elapsed" in '' | *[!0-9]*) elapsed=0 ;; esac
    if [ "$elapsed" -ge 3600 ]; then
      rec=$(printf 'REC %d:%02d:%02d' \
        $((elapsed / 3600)) $((elapsed / 60 % 60)) $((elapsed % 60)))
    else
      rec=$(printf 'REC %02d:%02d' $((elapsed / 60)) $((elapsed % 60)))
    fi
  fi

  refresh_updates
  updates=$(cat "$UPDATES_CACHE" 2>/dev/null || echo 0)
  case "$updates" in '' | *[!0-9]*) updates=0 ;; esac

  temp=$(cached "$RT/cpu-temp" 30 cpu_temp)
  media=$(cached "$RT/nowplaying" 5 now_playing)
  periph=$(cached "$RT/peripherals" 5 peripherals)

  hardware=$(join " · " "$temp" \
    "$(free -h | awk '/^Mem:/ { sub(/i$/, "", $3); printf "󰍛 %s", $3 }')")
  [ "$updates" -gt 0 ] && hardware=$(join " · " "$hardware" "󰏗 $updates")

  printf '%s\n' "$(join '  │  ' "$rec" "$media" "$hardware" "$periph" \
    "󰃭 $(date +'%d %b · %H:%M')")"

  sleep "$sleep_for"
done
