#!/bin/sh
# Toggle focus or move container to next active output (multi-monitor)
set -eu

action="${1:-focus}"

target=$(swaymsg -t get_outputs | jq -r '
  (map(select(.active)) | sort_by(.rect.x)) as $a |
  ($a | map(.focused) | index(true) // 0) as $c |
  if ($a | length) > 1 then
    $a[($c + 1) % ($a | length)].name
  else
    empty
  end
')

[ -z "$target" ] && exit 0

case "$action" in
  focus)
    swaymsg "focus output $target"
    ;;
  move)
    swaymsg "move container to output $target, focus output $target"
    ;;
esac
