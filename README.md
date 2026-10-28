# dotfiles

Sway desktop configuration for a ThinkPad X280 with an external 1080p monitor.
Managed with [GNU Stow](https://www.gnu.org/software/stow/) and themed with
pywal16.

## Stack

| Role | Program |
|---|---|
| Compositor | Sway (Wayland) |
| Terminal | foot |
| Shell | fish + starship |
| Launcher, menus | fuzzel |
| Notifications | mako |
| OSD | SwayOSD |
| Locker | swaylock |
| File manager | Thunar |
| Media | mpv |
| System monitor | btop |
| Multiplexer | tmux |
| Font | JetBrainsMono Nerd Font |
| Icons | Papirus-Dark |
| Cursor | Doro |

## Layout

```
bin/                    scripts installed to ~/.local/bin
btop/                   system monitor
  menu-launcher         fuzzel launcher with flatpak data dirs
  pick-fuzzel           shared dmenu wrapper for every picker
  sway-output-toggle    move focus or a window to the other display
  window-switcher       fuzzel window list
fastfetch/              login info and logo
fish/                   shell config, aliases, flatpak dirs
foot/                   terminal
fuzzel/                 launcher appearance
git/                    git identity and defaults
gtk/                    GTK3/GTK4 settings
mpv/                    video player
pkg-lists/              installed package snapshots
pipewire/               audio quirks for browsers and voice apps
starship/               prompt
sway/                   Sway config and helper scripts
systemd/                user units (failure notifications, wakatime updater)
thunar/                 Thunar settings and context menu actions
tmux/                   tmux config
wal/                    pywal templates for every themed program
xdg/                    MIME defaults, user dirs, fontconfig, Wayland env
xdg-desktop-portal-wlr/ screen sharing portal
install.sh              stow wrapper
```

## Install

```bash
git clone https://github.com/shironxn/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` links each package into `$HOME` with `stow -R`. Existing files
that are not part of the repo are left alone; a conflict means the same path
already exists and has to be moved aside first.

## Requirements

`pkg-lists/pacman-explicit.txt` is the full snapshot. The packages the config
actually calls:

```bash
sudo pacman -S sway swaylock swayosd foot fuzzel fish starship tmux \
  thunar mako wl-clipboard cliphist grim slurp wf-recorder brightnessctl \
  playerctl pipewire wireplumber networkmanager jq imagemagick ddcutil \
  papirus-icon-theme ttf-jetbrains-mono-nerd polkit-gnome mpv \
  ffmpegthumbnailer xdg-desktop-portal-wlr eza bat fastfetch
yay -S python-pywal16
```

mpv is the default handler for video and audio, File Roller for archives,
Evince for PDF. The Doro cursor theme is installed into
`~/.local/share/icons/Doro`.

## Keybindings

`Super` is the Mod4 key.

### Basics

| Key | Action |
|---|---|
| `Super+Return` | terminal |
| `Super+d` | application launcher |
| `Super+Tab` | window switcher |
| `Super+Shift+q` | close window |
| `Super+Shift+c` | reload config |
| `Super+Shift+e` | exit Sway |
| `Super+/` | keybinding cheatsheet |

### Utilities

| Key | Action |
|---|---|
| `Super+Shift+s`, `Print` | screenshot (area, window, or display) |
| `Super+Shift+r` | screen recorder (area, window, or display) |
| `Super+Shift+w` | wallpaper picker |
| `Super+Shift+v` | clipboard history |
| `Super+Alt+v` | clear clipboard history |
| `Super+Shift+BackSpace` | lock screen |
| `Super+Shift+Delete` | power menu |

### Window

| Key | Action |
|---|---|
| `Super+h/j/k/l`, `Super+arrows` | move focus |
| `Super+Shift+h/j/k/l` | move window |
| `Super+o` | focus the other display |
| `Super+Shift+o` | move window to the other display |
| `Super+b`, `Super+v` | split horizontal, vertical |
| `Super+s`, `Super+w`, `Super+e` | stacking, tabbed, toggle split |
| `Super+f` | fullscreen |
| `Super+Shift+space` | toggle floating |
| `Super+p` | floating and sticky |
| `Super+space` | toggle focus between tiling and floating |
| `Super+a` | focus parent |
| `Super+r` then `h/j/k/l` | resize |
| `Super+Shift+minus`, `Super+minus` | send to scratchpad, show scratchpad |

### Workspaces

`Super+1..0` switches workspace, `Super+Shift+1..0` moves the focused window
to it.

### Hardware keys

Volume, mute, microphone mute, brightness, keyboard backlight, and media
playback are bound to the XF86 keys.

## Theming

Changing the wallpaper runs `sway/.config/sway/scripts/wal-theme.sh`, which
calls pywal and reloads everything that reads the palette:

| Target | Template | Applies to |
|---|---|---|
| `colors-sway` | Sway variables | borders, bar, workspace colors |
| `colors-foot.ini` | foot | terminal palette |
| `colors-fuzzel.ini` | fuzzel | launcher |
| `colors-mako` | mako | notifications |
| `colors-gtk.css` | GTK3 | GTK apps and Thunar |
| `colors-swaylock` | swaylock | lock screen |
| `style-swayosd.css` | SwayOSD | volume and brightness overlay |

The lock screen uses a blurred, darkened copy of the wallpaper
(`~/.cache/wal/bg-lock.jpg`) generated by the same script.

## Displays

Both outputs run at scale 1.0 with RGB subpixel rendering. Workspaces 1-6 are
pinned to `HDMI-A-2` and 7-10 to `eDP-1`, each with the other output as a
fallback, so a single-display setup still works.

## Status bar

`sway/.config/sway/scripts/status.sh` prints one line:

```
REC 00:42  │  󰎆 Artist - Title  │  󰔏 54°C · 󰍛 8.2G  │  󰖩 · 󰖀 45% · 󰍭 · 󰂀 78%  │  󰃭 28 Oct · 19:51
```

Recording state and now-playing are on the left so their text grows and
shrinks without moving the hardware, peripheral, and clock sections. Each
value is cached in `/tmp` for 3-60 seconds; the bar refreshes every second
only while recording.

## Notes

Some config is specific to this machine and can be dropped when reusing the
repo elsewhere:

- `sway/.config/sway/config.d/input.conf`: the NACODEX wireless dongle repeats
  a brightness key, so two of its interfaces are disabled.
- `sway/.config/sway/config.d/output.conf`, `workspaces.conf`,
  `sway-output-toggle`: output names `eDP-1` and `HDMI-A-2`.
- `sway/.config/sway/config.d/wacom.conf`: maps a Wacom tablet to `HDMI-A-2`.
- `sway/.config/sway/scripts/brightness-switch.sh`: uses `ddcutil` for the
  external monitor.
- `xdg/.config/mimeapps.list`: defaults include Brave and Sober.
