#!/usr/bin/env bash
# Float Telegram's secondary windows (video/voice call, media viewer) as a
# sticky panel pinned to the top-right corner of the focused output.
#
# Telegram creates the call window as a separate Wayland toplevel that shares
# app_id "org.telegram.desktop" with the main window, and whose title is only
# the peer name (Calls::Panel::initWindow -> window()->setTitle(_user->name())).
# No static sway criterion can tell those windows apart, so this watcher treats
# "another Telegram window appeared while the main one is already open" as the
# signal. Fixed panel size in px, pinned to the top-right of the focused
# output. Tweak PANEL_WIDTH/PANEL_HEIGHT/MARGIN/BAR_HEIGHT to taste.
#
# There is no usable floor on the call window: sway can resize it far below
# st::callWidthMin (380px in calls.style, which only clamps the initial and
# saved geometry) -- 120x160 works. What does not scale is the self-preview
# bubble: a fixed 160x110, or a full-width 360x120 strip once your camera is on
# (calls.style callOutgoingPreviewMin). Shrinking the panel makes that bubble
# cover proportionally more of the remote video, and there is no UI to hide it
# -- only switching your camera off does (VideoBubble::updateVisibility hides it
# when the track is Inactive). 360 is the bubble's own width, so it fits exactly.
#
# Usage:
#   telegram-pip.sh          watch for new windows and pin them (autostart)
#   telegram-pip.sh apply    re-pin the current call window by hand
#   telegram-pip.sh stop     kill the watcher
#
# 'apply' exists because Telegram saves the call panel geometry when you resize
# it manually (Core::App().settings().callPanelPosition()), and the watcher only
# reacts to windows appearing -- so a manual resize sticks until you re-apply.

set -u

APP_ID="org.telegram.desktop"
PANEL_WIDTH=360
PANEL_HEIGHT=480
MARGIN=24
BAR_HEIGHT=30

RUNTIME="${XDG_RUNTIME_DIR:-/tmp}"
PIDFILE="$RUNTIME/telegram-pip.pid"

telegram_cons_by_area() {
    # Descending area: the main window fills the workspace, so it sorts first and
    # every secondary window (call panel, media viewer) comes after it.
    swaymsg -t get_tree |
        jq -r --arg app "$APP_ID" '
            [.. | objects | select(.app_id == $app)
                | {id, area: (.rect.width * .rect.height)}]
            | sort_by(-.area) | .[] | "\(.id) \(.area)"'
}

apply_panel() {
    local con=$1 width=$2 height=$3 x=$4 y=$5

    swaymsg "[con_id=$con] floating enable, sticky enable, border pixel 2, \
resize set $width $height, move position $x $y" >/dev/null
}

con_rect() {
    swaymsg -t get_tree |
        jq -r --argjson id "$1" \
            '.. | objects | select(.id == $id)
                | "\(.rect.width) \(.rect.height) \(.rect.x) \(.rect.y)"'
}

place_panel() {
    local con=$1
    local x y w ox oy width height got gx gy

    # Focused output geometry, so the panel lands on the screen in use.
    read -r ox oy w _ < <(
        swaymsg -t get_outputs |
            jq -r '.[] | select(.focused)
                | "\(.rect.x) \(.rect.y) \(.rect.width) \(.rect.height)"'
    )
    [ -n "${w:-}" ] || return 0

    width=$PANEL_WIDTH
    height=$PANEL_HEIGHT
    x=$((ox + w - width - MARGIN))
    y=$((oy + BAR_HEIGHT + MARGIN))

    # Telegram re-applies its saved call panel geometry right after showing the
    # window, which beats the first resize. Re-assert until it sticks.
    #
    # sway offsets a floating window's rect from the requested position (border
    # + bar). Probe the offset once and apply its inverse, instead of correcting
    # in the loop: a stale rect read there would compound the correction.
    apply_panel "$con" "$width" "$height" "$x" "$y"
    sleep 0.4
    got=$(con_rect "$con")
    [ -n "$got" ] || return 0 # window closed meanwhile
    read -r _ _ gx gy <<<"$got"
    x=$((x - (gx - x)))
    y=$((y - (gy - y)))

    for _ in 1 2 3 4; do
        apply_panel "$con" "$width" "$height" "$x" "$y"
        sleep 0.4
        got=$(con_rect "$con")
        [ -n "$got" ] || return 0
        [ "$(echo "$got" | cut -d' ' -f1-2)" = "$width $height" ] && return 0
    done
}

case "${1:-watch}" in
stop)
    if [ -s "$PIDFILE" ]; then
        # The watcher is a setsid session leader, so signal the whole group and
        # take swaymsg/jq down with it.
        pid=$(cat "$PIDFILE")
        kill -TERM -- "-$pid" 2>/dev/null || kill -TERM "$pid" 2>/dev/null
        rm -f "$PIDFILE"
    fi
    exit 0
    ;;
apply)
    # Skip the largest window (the main one); pin every secondary window.
    while read -r con _; do
        place_panel "$con"
    done < <(telegram_cons_by_area | tail -n +2)
    exit 0
    ;;
esac

# One watcher only. Duplicates exit immediately.
if [ -s "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    exit 0
fi
printf '%s\n' "$$" >"$PIDFILE"
trap 'rm -f "$PIDFILE"' EXIT

# Process substitution keeps the loop in this shell: one process, and the pid
# stays owned by the watcher for the whole lifetime.
while read -r event; do
    app=$(jq -r '.app_id // ""' <<<"$event")
    [ "$app" = "$APP_ID" ] || continue
    con=$(jq -r '.id' <<<"$event")
    # The first Telegram window is the main one; leave it tiled.
    [ "$(telegram_cons_by_area | wc -l)" -gt 1 ] || continue
    place_panel "$con"
done < <(swaymsg -t subscribe -m '[ "window" ]' |
    jq --unbuffered -c 'select(.change == "new") | .container | {id, app_id}')
