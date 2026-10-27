#!/bin/sh
# Cliphist wipe with feedback
set -eu

if cliphist wipe 2>/dev/null; then
  notify-send -t 2000 'Clipboard' 'History wiped'
else
  notify-send -u critical -t 3000 'Clipboard' 'Wipe failed'
fi
