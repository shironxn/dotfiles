#!/bin/sh
# Popup keybinds — parse LIVE dari keybinds.conf (SSOT = config, bukan daftar manual)
# Label + icon di-hash dari isi baris; perintah tak-dikenal ditampilkan mentah (fallback).
# Bind: Super+/ (keybinds.conf). Style: NF icon + indent, konsisten sama bar.
set -eu
command -v pick-fuzzel >/dev/null || exit 1
CONF="$HOME/.config/sway/config.d/keybinds.conf"

awk '
function label(cmd) {
  if (cmd ~ /swaynag/)                    return "exit sway (konfirmasi)"
  if (cmd ~ /keybinds.sh/)                return "cheatsheet keybind"
  if (cmd ~ /powermenu/)                  return "power menu"
  if (cmd ~ /screenshot/)                 return "screenshot"
  if (cmd ~ /scripts\/wallpaper/)         return "ganti wallpaper"
  if (cmd ~ /cliphist decode/)            return "riwayat clipboard"
  if (cmd ~ /cliphist-wipe/)              return "bersihkan clipboard"
  if (cmd ~ /output-volume -5/)           return "volume −5"
  if (cmd ~ /output-volume \+5/)          return "volume +5"
  if (cmd ~ /mute-toggle/)                return "mute volume"
  if (cmd ~ /mic-toggle|MicMute/)         return "mute mikrofon"
  if (cmd ~ /brightness-switch.sh up/)    return "brightness +"
  if (cmd ~ /brightness-switch.sh down/)  return "brightness −"
  if (cmd ~ /osd.sh kbd up/)              return "lampu keyboard +"
  if (cmd ~ /osd.sh kbd down/)            return "lampu keyboard −"
  if (cmd ~ /\$term/)                     return "buka terminal"
  if (cmd ~ /\$menu/)                     return "app launcher"
  if (cmd ~ /window-switcher/)            return "pindah window (switcher)"
  if (cmd ~ /kill/)                       return "tutup window"
  if (cmd ~ /reload/)                     return "reload config"
  if (cmd ~ /swaylock/)                   return "lock screen"
  if (cmd ~ /focus left/)                 return "fokus kiri"
  if (cmd ~ /focus down/)                 return "fokus bawah"
  if (cmd ~ /focus up/)                   return "fokus atas"
  if (cmd ~ /focus right/)                return "fokus kanan"
  if (cmd ~ /move left/)                  return "pindah ke kiri"
  if (cmd ~ /move down/)                  return "pindah ke bawah"
  if (cmd ~ /move up/)                    return "pindah ke atas"
  if (cmd ~ /move right/)                 return "pindah ke kanan"
  if (cmd ~ /move container to workspace/) { n = cmd; sub(/.*number /, "", n); return "→ workspace " n }
  if (cmd ~ /workspace number/)           { n = cmd; sub(/.*number /, "", n); return "workspace " n }
  if (cmd ~ /splith/)                     return "split horizontal"
  if (cmd ~ /splitv/)                     return "split vertikal"
  if (cmd ~ /stacking/)                   return "layout: stacking"
  if (cmd ~ /tabbed/)                     return "layout: tabbed"
  if (cmd ~ /toggle split/)               return "layout: toggle split"
  if (cmd ~ /fullscreen/)                 return "fullscreen"
  if (cmd ~ /floating toggle; sticky/)    return "floating + sticky"
  if (cmd ~ /floating toggle/)            return "floating on/off"
  if (cmd ~ /focus mode_toggle/)          return "fokus tiling↔floating"
  if (cmd ~ /focus parent/)               return "fokus ke parent"
  if (cmd ~ /move scratchpad/)            return "kirim ke scratchpad"
  if (cmd ~ /scratchpad show/)            return "scratchpad show"
  if (cmd ~ /shrink width/)               return "resize: sempitkan"
  if (cmd ~ /grow width/)                 return "resize: lebarkan"
  if (cmd ~ /shrink height/)              return "resize: pendekkan"
  if (cmd ~ /grow height/)                return "resize: tinggikan"
  if (cmd ~ /mode "default"/)             return "keluar mode resize"
  if (cmd ~ /mode "resize"/)              return "masuk mode resize"
  sub(/^exec /, "", cmd)
  gsub(/.*sway\/scripts\//, "", cmd)
  gsub(/\.sh$/, "", cmd)
  return cmd
}
function icon(h) {
  hl = tolower(h)
  if (hl ~ /basics|key bindings/)  return "󰇖"
  if (hl ~ /util/)                 return "󰆏"
  if (hl ~ /volume|brightness/)    return "󰕾"
  if (hl ~ /keyboard/)             return "󰌌"
  if (hl ~ /focus/)                return "󰆐"
  if (hl ~ /window/)               return "󰊖"
  if (hl ~ /workspace/)            return "󰲎"
  if (hl ~ /layout/)               return "󰆗"
  if (hl ~ /scratchpad/)           return "󰤼"
  if (hl ~ /resize/)               return "󰩨"
  return "▸"
}
/^# /{
  h = $0
  sub(/^#+ */, "", h)
  gsub(/──|—/, "", h)
  i = index(h, "(")
  if (i > 1) h = substr(h, 1, i - 1)
  gsub(/ +$/, "", h)
  gsub(/^ +| +$/, "", h)
  if (h != "" && h !~ /──/) printf "\n%s  %s\n", icon(h), toupper(h)
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
' "$CONF" | pick-fuzzel " keybinds " -w 100 -l 28 >/dev/null
