#!/bin/bash

while true; do
  battery=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo "?")
  charge=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo "?")

  case "$charge" in
    Charging) charge_icon="󰂄" ;;
    Full)     charge_icon="󰁹" ;;
    *)        charge_icon="󰁿" ;;
  esac

  volume=$(pamixer --get-volume-human 2>/dev/null || echo "MUTED")
  wifi=$(nmcli -t -f active,ssid dev wifi | awk -F: '$1=="yes"{print $2; exit}')
  [ -z "$wifi" ] && wifi="No WiFi"
  uptime_str=$(uptime -p | sed 's/up //')
  date_str=$(date +'%a %d %b %H:%M')

  echo "󰖩 ${wifi} | 󰕾 ${volume} | ${charge_icon} ${battery}% | 󰔟 ${uptime_str} | 󰃭 ${date_str}<span size='large'> </span>"

  sleep 1
done
