#!/bin/sh
# Keybinding cheatsheet, generated from keybinds.conf so it cannot drift.
set -eu

pkill -f 'fuzzel.* keybinds ' 2>/dev/null && exit 0

CONF="${XDG_CONFIG_HOME:-$HOME/.config}/sway/config.d/keybinds.conf"
[ -f "$CONF" ] || exit 0

# Size the popup to the focused monitor so it never covers the screen.
h=$(swaymsg -t get_outputs 2>/dev/null |
  jq -r '([.[] | select(.focused)] | first // .[0]) | .rect.height / .scale' 2>/dev/null || true)
case "${h%%.*}" in
'' | *[!0-9]*) lines=10 ;;
*) lines=$(((${h%%.*} - 200) / 26)) ;;
esac
[ "$lines" -lt 6 ] && lines=6
[ "$lines" -gt 14 ] && lines=14

# Every substitution below turns a config fragment into the words a person
# would use for it; order matters, the first match wins.
awk '
function tidy(cmd,   c) {
  c = cmd
  sub(/^exec /, "", c)
  sub(/^~\/\.config\/sway\/scripts\//, "", c)
  sub(/^thunar ~\/pictures\/wallpapers$/, "wallpaper folder", c)
  sub(/\.sh( |$)/, " ", c)
  sub(/ +$/, "", c)
  sub(/^swayosd-client .*/, "volume OSD", c)
  sub(/^cliphist list.*/, "clipboard history", c)
  sub(/^cliphist wipe.*/, "clear clipboard", c)
  sub(/^swaynag.*/, "exit sway", c)
  sub(/^swaylock$/, "lock screen", c)
  sub(/^swaymsg exit$/, "logout", c)
  sub(/^\$term$/, "terminal", c)
  sub(/^fuzzel$/, "launcher", c)
  sub(/^kill$/, "close window", c)
  sub(/^reload$/, "reload config", c)
  sub(/^playerctl /, "media ", c)
  sub(/^splith$/, "split horizontal", c)
  sub(/^splitv$/, "split vertical", c)
  sub(/^fullscreen$/, "fullscreen", c)
  sub(/^floating toggle$/, "floating", c)
  sub(/^sticky toggle$/, "sticky", c)
  sub(/^focus mode_toggle$/, "tiling / floating", c)
  sub(/^focus parent$/, "parent container", c)
  sub(/^move scratchpad$/, "to scratchpad", c)
  sub(/^scratchpad show$/, "scratchpad", c)
  sub(/^workspace number /, "workspace ", c)
  sub(/^move container to workspace number /, "move to workspace ", c)
  sub(/^output focus$/, "focus other monitor", c)
  sub(/^output move$/, "move to other monitor", c)
  sub(/^windows$/, "window switcher", c)
  sub(/^power$/, "power menu", c)
  sub(/^record$/, "screen recorder", c)
  sub(/^keymap$/, "this cheatsheet", c)
  sub(/^mic-toggle$/, "microphone mute", c)
  sub(/^kbdlight (up|down)$/, "keyboard backlight", c)
  sub(/^brightness up$/, "screen brighter", c)
  sub(/^brightness down$/, "screen dimmer", c)
  sub(/^screenshot$/, "screenshot", c)
  sub(/^mode "resize"$/, "enter resize mode", c)
  sub(/^mode "default"$/, "leave resize mode", c)
  gsub(/"/, "", c)
  sub(/ [0-9]+px$/, "", c)
  gsub(/  +/, " ", c)
  sub(/ +$/, "", c)
  return c
}
/^# ---/ { next }
/^# / {
  h = $0
  sub(/^# +/, "", h)
  sub(/ \(.*/, "", h)
  if (h != "" && h != "Key Bindings") printf "\n%s\n", toupper(h)
  next
}
/^[ \t]*bindswitch/ {
  line = $0
  sub(/^[ \t]*bindswitch +/, "", line)
  sub(/^--locked +/, "", line)
  i = index(line, " ")
  printf "%-24s %s\n", substr(line, 1, i - 1), "lock screen (lid close)"
  next
}
/^[ \t]*bindsym/ {
  line = $0
  sub(/^[ \t]*bindsym +/, "", line)
  sub(/^--locked +/, "", line)
  i = index(line, " ")
  combo = substr(line, 1, i - 1)
  cmd = substr(line, i + 1)
  gsub(/\$mod/, "Super", combo)
  gsub(/\$left/, "h", combo); gsub(/\$down/, "j", combo)
  gsub(/\$up/, "k", combo);   gsub(/\$right/, "l", combo)
  gsub(/Mod4\+/, "Super+", combo)
  printf "%-24s %s\n", combo, tidy(cmd)
}
' "$CONF" | pick-fuzzel " keybinds " -w 52 -l "$lines" >/dev/null || true
