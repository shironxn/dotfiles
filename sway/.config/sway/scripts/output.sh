#!/bin/sh
# Focus the next active output, or move the focused container there.
#   output.sh focus|move
set -eu

action="${1:-focus}"

target=$(swaymsg -t get_outputs | jq -r '
  (map(select(.active)) | sort_by(.rect.x)) as $o |
  ($o | map(.focused) | index(true) // 0) as $i |
  if ($o | length) > 1 then $o[($i + 1) % ($o | length)].name else empty end
')

[ -n "$target" ] || exit 0

case "$action" in
focus) swaymsg "focus output $target" ;;
move) swaymsg "move container to output $target, focus output $target" ;;
esac
