# dotfiles

Sway on Arch Linux, managed with [GNU Stow](https://www.gnu.org/software/stow/).
Themes come from pywal16, driven by the wallpaper.

Machine-specific settings (outputs, workspace pinning, input quirks) live in an
optional `host.conf`, so the rest stays portable.

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
brave/                  Wayland flags for Brave
btop/                   system monitor (uses terminal palette)
fastfetch/              login info and ASCII art
fish/                   shell config, aliases, flatpak paths
fontconfig/             LCD subpixel hinting, Japanese glyph preference
foot/                   terminal config and search keybinds
fuzzel/                 launcher appearance
git/                    git defaults
gtk/                    GTK3/GTK4 settings, cursor inheritance
mpv/                    video player and hardware decoding
pipewire/               audio quirks for browsers and voice apps
starship/               prompt
sway/                   compositor config and helper scripts
  host.conf.example     template for machine-specific overrides
  scripts/              desktop helpers (see Scripts)
systemd/                tmux user unit
thunar/                 Thunar context menu actions
tmux/                   tmux status and keybindings
wal/                    pywal templates, one per themed program
xdg/                    MIME defaults, user dirs, Wayland env
xdg-desktop-portal-wlr/ screen sharing portal
install.sh              stow wrapper and dependency check
LICENSE                 MIT
```

## Requirements

```bash
sudo pacman -S sway swaybg swaylock swayosd foot fuzzel fish starship tmux \
  thunar mako wl-clipboard cliphist grim slurp wf-recorder brightnessctl \
  playerctl pipewire wireplumber networkmanager jq imagemagick ddcutil \
  papirus-icon-theme ttf-jetbrains-mono-nerd polkit-gnome mpv \
  ffmpegthumbnailer xdg-desktop-portal-wlr stow eza bat fastfetch \
  adw-gtk-theme pacman-contrib btop neovim
yay -S python-pywal16
```

Optional:

- `noto-fonts-cjk` for the Japanese font rule in `fontconfig/`.
- A cursor theme named `Doro` in `~/.local/share/icons/Doro`. Any XCursor theme
  works if you rename it in all six places that reference it:

  ```
  gtk/.config/gtk-3.0/settings.ini
  gtk/.config/gtk-4.0/settings.ini
  gtk/.icons/default/index.theme
  sway/.config/sway/config.d/input.conf
  sway/.config/sway/scripts/wallpaper.sh
  install.sh
  ```

## Install

```bash
git clone https://github.com/shironxn/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` checks for required commands, creates `~/.config`, `~/.local/bin`,
`~/pictures/screenshots`, and `~/videos/recordings`, then links each package
with `stow -R`. Two exceptions: `thunar/.config/Thunar/uca.xml` is copied, not
linked, because Thunar replaces the symlink whenever an action is edited; and
Thunar's built-in wallpaper plugin is disabled when the script can move it,
since that plugin only works on XFCE and GNOME.

Generate a palette from a wallpaper, then reload Sway (`Super+Shift+c`):

```bash
~/.config/sway/scripts/wallpaper.sh -i ~/pictures/wallpapers/<wallpaper.jpg>
```

## Machine-specific setup (`host.conf`)

Sway detects connected outputs and assigns workspaces on its own. For a fixed
multi-monitor layout, pinned workspaces, or device quirks, copy the template:

```bash
cp ~/.config/sway/host.conf.example ~/.config/sway/host.conf
```

`host.conf` is git-ignored and loaded after everything else, so it wins.

```sway
output eDP-1 scale 1.0 subpixel rgb position 1920 0
output HDMI-A-2 scale 1.0 subpixel rgb position 0 0

workspace 1 output HDMI-A-2 eDP-1
workspace 7 output eDP-1 HDMI-A-2

input "0000:0000:Example_Mouse" {
    accel_profile flat
    pointer_accel 0
}
```

## Overrides

Three files load last, so anything set there wins:

| File | Loaded by |
|---|---|
| `~/.gitconfig.local` | `git/.config/git/config` (`[include]`) |
| `~/.config/fish/config.local.fish` | `fish/.config/fish/config.fish` |
| `~/.config/sway/host.conf` | `sway/.config/sway/config` |

Files under `xdg/` have no hook and apply at the next login. Check
`mimeapps.list` (Brave as browser, Loupe for images, a Roblox handler) and
`user-dirs.dirs` (lowercase `~/downloads`, `~/pictures`, `~/videos`) before
installing, or delete them from `$HOME` afterwards.

## Keybindings

`Super` is Mod4. The full list lives in `keybinds.conf` and is shown by
`Super+/`, which reads that file directly, so it cannot drift from the config.

| Key | Action |
|---|---|
| `Super+Return` | Terminal |
| `Super+d` | Launcher |
| `Super+Tab` | Window switcher |
| `Super+/` | Keybinding cheatsheet |
| `Super+Shift+s`, `Print` | Screenshot |
| `Super+Shift+r` | Screen recorder |
| `Super+Shift+w` | Open `~/pictures/wallpapers` in Thunar |
| `Super+Shift+v` | Clipboard history |
| `Super+Shift+BackSpace` | Lock |
| `Super+Shift+Delete` | Power menu |

Hardware keys: volume and mute through `swayosd-client`, microphone through
`mic-toggle.sh`, brightness on the internal panel through `swayosd-client` and
on external monitors through `ddcutil`, keyboard backlight through the OSD,
media through `playerctl`. Closing the lid locks the screen, then logind
suspends.

## Scripts

Helpers live in `sway/.config/sway/scripts/`.

| Script | Trigger | Purpose |
|---|---|---|
| `wallpaper.sh` | Thunar action, autostart `-R` | Build the pywal palette and repaint clients |
| `keymap.sh` | `Super+/` | Cheatsheet generated from `keybinds.conf` |
| `windows.sh` | `Super+Tab` | Window switcher across workspaces |
| `screenshot.sh` | `Print`, `Super+Shift+s` | Area, window, or display to `~/pictures/screenshots` |
| `record.sh` | `Super+Shift+r` | Toggle a recording with desktop audio |
| `power.sh` | `Super+Shift+Delete` | Session menu |
| `brightness.sh` | brightness keys | Panel backlight, or DDC/CI on external monitors |
| `kbdlight.sh` | keyboard backlight keys | Step the vendor LED, reporting through the OSD |
| `mic-toggle.sh` | mic mute key | Mute capture sources (monitor loopbacks excluded) |
| `output.sh` | `Super+o`, `Super+Shift+o` | Move focus, or the window, to the next output by x position |
| `status.sh` | bar `status_command` | The bar |

## Theming

Picking a wallpaper runs `wallpaper.sh`, which regenerates every template and
reloads the clients that read them:

| Template | Target | Applies to |
|---|---|---|
| `colors-sway` (pywal builtin) | Sway variables | Borders, bar, workspace buttons |
| `colors-foot.ini` | foot | Terminal 16-color palette |
| `colors-fuzzel.ini` | fuzzel | Launcher and dmenu dialogs |
| `colors-mako` | mako | Notification popups |
| `colors-gtk.css` | GTK3 | GTK applications and Thunar |
| `colors-swaylock` | swaylock | Lock screen ring and indicators |
| `style-swayosd.css` | SwayOSD | Volume and brightness OSD |

`colors-sway` comes from pywal itself; the other templates live in `wal/`. The
script pushes border and bar colours over IPC, since the bar only re-reads its
palette on a full reload.

The lock screen background is a blurred copy of the wallpaper, rendered at the
largest active display size. `btop` uses its builtin `TTY` theme, so it follows
the terminal palette without a template.

## Status bar

`status.sh` groups the bar into modules:

```
REC 00:42  │  󰎆 Artist - Track  │  󰔏 54°C · 󰍛 8.2G · 󰏗 13  │  󰖩 · 󰖀 45% · 󰍭 · 󰂀 78%  │  󰃭 28 Oct · 19:51
```

The recording timer and now-playing block are prepended only when active, so the
hardware and clock segments never shift. Microphone mute appears only while
muted. CPU temperature takes the first matching package or core sensor. Probes
are cached for 3–3600 seconds depending on cost; the update check, which queries
every repo, runs detached. The bar redraws every 3 seconds, or every second
while recording.

## License

MIT. See [LICENSE](LICENSE).
