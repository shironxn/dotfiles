#!/bin/sh
# Generate the keybinding cheatsheet from keybinds.conf and show it in fuzzel.
set -eu

command -v pick-fuzzel >/dev/null || exit 1
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/sway/config.d/keybinds.conf"

awk '
function label(cmd,   n) {
  if (cmd ~ /swaynag/)                     return "exit sway"
  if (cmd ~ /keybinds\.sh/)                return "cheatsheet"
  if (cmd ~ /powermenu/)                   return "power menu"
  if (cmd ~ /screenshot/)                  return "screenshot"
  if (cmd ~ /output-toggle focus/)         return "focus other monitor"
  if (cmd ~ /output-toggle move/)          return "move window to other monitor"
  if (cmd ~ /screenrec/)                   return "screen recorder"
  if (cmd ~ /scripts\/wallpaper/)          return "wallpaper picker"
  if (cmd ~ /wal-theme/)                   return "set wallpaper"
  if (cmd ~ /cliphist decode/)             return "clipboard history"
  if (cmd ~ /cliphist-wipe/)               return "clear clipboard"
  if (cmd ~ /output-volume -5/)            return "volume down"
  if (cmd ~ /output-volume \+5/)           return "volume up"
  if (cmd ~ /mute-toggle/)                 return "mute output"
  if (cmd ~ /mic-toggle/)                  return "mute microphone"
  if (cmd ~ /brightness-switch\.sh up/)    return "brightness up"
  if (cmd ~ /brightness-switch\.sh down/)  return "brightness down"
  if (cmd ~ /osd\.sh kbd up/)              return "keyboard light up"
  if (cmd ~ /osd\.sh kbd down/)            return "keyboard light down"
  if (cmd ~ /playerctl play-pause/)        return "play / pause"
  if (cmd ~ /playerctl next/)              return "next track"
  if (cmd ~ /playerctl previous/)          return "previous track"
  if (cmd ~ /playerctl stop/)              return "stop playback"
  if (cmd ~ /\$term/)                      return "terminal"
  if (cmd ~ /\$menu/)                      return "app launcher"
  if (cmd ~ /window-switcher/)             return "window switcher"
  if (cmd ~ /^kill/)                       return "close window"
  if (cmd ~ /^reload/)                     return "reload config"
  if (cmd ~ /swaylock/)                    return "lock screen"
  if (cmd ~ /move container to workspace/) { n = cmd; sub(/.*number /, "", n); return "move to workspace " n }
  if (cmd ~ /workspace number/)            { n = cmd; sub(/.*number /, "", n); return "workspace " n }
  if (cmd ~ /^splith$/)                    return "split horizontal"
  if (cmd ~ /^splitv$/)                    return "split vertical"
  if (cmd ~ /floating toggle; sticky/)     return "floating + sticky"
  if (cmd ~ /focus mode_toggle/)           return "focus tiling / floating"
  if (cmd ~ /resize /)                     { sub(/ [0-9]+px$/, "", cmd); return cmd }
  if (cmd ~ /mode "default"/)              return "leave resize mode"
  if (cmd ~ /mode "resize"/)               return "enter resize mode"
  return cmd
}
function icon(h) {
  h = tolower(h)
  if (h ~ /key binding/)     return "󰌌"
  if (h ~ /basic/)           return "󰇖"
  if (h ~ /util/)            return "󰆏"
  if (h ~ /media/)           return "󰎆"
  if (h ~ /backlight/)       return "󰌌"
  if (h ~ /volume|brightness/) return "󰕾"
  if (h ~ /focus|move/)      return "󰆐"
  if (h ~ /monitor/)         return "󰍹"
  if (h ~ /workspace/)       return "󰲎"
  if (h ~ /layout/)          return "󰆗"
  if (h ~ /scratchpad/)      return "󰤼"
  if (h ~ /resize/)          return "󰩨"
  return "▸"
}
/^# /{
  h = $0
  sub(/^#+ */, "", h)
  gsub(/─+/, "", h)
  i = index(h, "(")
  if (i > 1) h = substr(h, 1, i - 1)
  gsub(/^ +| +$/, "", h)
  if (h != "") printf "\n%s  %s\n", icon(h), toupper(h)
  next
}
/^[ \t]*bindsym/{
  line = $0
  sub(/^[ \t]*bindsym */, "", line)
  sub(/^--locked */, "", line)
  idx = index(line, " ")
  combo = substr(line, 1, idx - 1)
  cmd   = substr(line, idx + 1)
  gsub(/\$mod/, "Super", combo)
  gsub(/\$left/, "h", combo)
  gsub(/\$down/, "j", combo)
  gsub(/\$up/, "k", combo)
  gsub(/\$right/, "l", combo)
  printf "  %-21s %s\n", combo, label(cmd)
}
' "$CONF" | pick-fuzzel " keybinds " -w 75 -l 20 >/dev/null
