#!/bin/sh
# Keybinding cheatsheet popup (responsive & toggleable)
set -eu

# Toggle: close if already running
if pkill -f 'fuzzel.* keybinds ' 2>/dev/null; then
  exit 0
fi

command -v pick-fuzzel >/dev/null || exit 1

# Adaptive size based on active monitor effective resolution
h=$(swaymsg -t get_outputs 2>/dev/null | jq -r '([.[] | select(.focused)] | first // .[0]) | .rect.height / .scale' 2>/dev/null || echo 1080)
h=${h%.*}

if [ "${h:-1080}" -lt 800 ]; then
  lines=7
  width=38
elif [ "${h:-1080}" -lt 1000 ]; then
  lines=8
  width=40
else
  lines=10
  width=42
fi

cat << 'EOF' | pick-fuzzel " keybinds " -w "$width" -l "$lines" >/dev/null || true
Super+Return         󰇖 terminal
Super+d              󰇖 launcher
Super+Shift+q        󰇖 close window
Super+Tab            󰇖 switcher
Super+Shift+c        󰇖 reload config
Super+Shift+e        󰇖 exit sway
Print / Super+Sh+s   󰆏 screenshot
Super+Shift+r        󰆏 recorder
Super+Shift+w        󰆏 wallpaper
Super+Shift+v        󰆏 clipboard
Super+Alt+v          󰆏 clear clip
Super+Shift+Bksp     󰆏 lock screen
Super+Shift+Delete   󰆏 power menu
Super+hjkl / arrows  󰆐 focus move
Super+Shift+hjkl/arr 󰆐 window move
Super+1..0           󰲎 workspace 1..10
Super+Shift+1..0     󰲎 move to ws 1..10
Super+o / S+Shift+o  󰍹 focus/move monitor
Super+b / Super+v    󰆗 split h / v
Super+s / w / e      󰆗 layout mode
Super+f              󰆗 fullscreen
Super+Shift+space    󰆗 floating toggle
Super+p              󰆗 sticky toggle
Super+space          󰆗 focus tiling/float
Super+a              󰆗 focus parent
Super+minus          󰤼 scratchpad show
Super+Shift+minus    󰤼 scratchpad move
Super+r              󰩨 resize mode
Audio keys           󰕾 volume / mute
Brightness keys      󰕾 screen brightness
Media keys           󰎆 play / track
EOF
