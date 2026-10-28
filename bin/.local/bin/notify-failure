#!/bin/bash
# notify-failure: alert for failed systemd user units.
# Called by notify-failure@.service with the failed unit name as $1.
# One notification per unit per day, so a crash loop does not spam the desktop.
set -u

unit="${1:-unknown}"
log="$HOME/backups/unit-failure.log"
rate_dir="$HOME/.cache/unit-failure-alert"
mark="$rate_dir/${unit//\//_}"
today=$(date +%F)

mkdir -p "$(dirname "$log")" "$rate_dir"
printf '%s FAILED: %s\n' "$(date '+%F %T')" "$unit" >>"$log"

if [ -f "$mark" ] && [ "$(cat "$mark" 2>/dev/null)" = "$today" ]; then
  exit 0
fi
printf '%s\n' "$today" >"$mark"

command -v notify-send >/dev/null &&
  notify-send -u critical "Unit failed: $unit" \
    "systemd user unit '$unit' failed. See: systemctl --user status $unit" 2>/dev/null || true

exit 0
