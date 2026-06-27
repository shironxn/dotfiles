#!/bin/sh
# Wal wrapper: apply theme (colorthief) + restart swayosd
set -eu

if [ "${1:-}" = "-R" ] || [ "${1:-}" = "--restore" ]; then
    wal "$@"
else
    PYTHONPATH=/tmp/pywal-venv/lib/python3.14/site-packages wal --backend colorthief "$@"
fi

# restart swayosd-server to pick up new style
killall swayosd-server 2>/dev/null || true
swayosd-server --style ~/.config/swayosd/style.css &
disown
