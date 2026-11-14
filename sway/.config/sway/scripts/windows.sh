#!/bin/sh
# Every Sway window in fuzzel, focused on selection.
set -eu

windows=$(swaymsg -t get_tree | jq -r '
  .. | objects | select(.type? == "workspace") as $ws | $ws | .. | objects
  | select(.name? and .pid?)
  | "[\($ws.name)] \(.app_id // .window_properties.class // "app"): \(.name | .[0:70])\t\(.id)"
')

[ -n "$windows" ] || exit 0

con_id=$(printf '%s\n' "$windows" |
  pick-fuzzel " switch to " -w 46 -l 10 --with-nth=1 --accept-nth=2) || exit 0

# The picker echoes only the id column; a stray value must not reach swaymsg.
case "$con_id" in '' | *[!0-9]*) exit 0 ;; esac

swaymsg "[con_id=$con_id] focus"
