# dotfiles

Clean, minimalist Sway desktop configuration on Arch Linux: dynamic pywal
theming, a lightweight status bar, 0px sharp corners, and a bloat-free Wayland
environment. Managed with [GNU Stow](https://www.gnu.org/software/stow/) and
themed with pywal16.

Hardware-specific settings (display outputs, workspace pinning, input quirks)
are decoupled into an optional `host.conf`, making the core configuration
portable across machines.

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
bin/                    general command-line scripts installed to ~/.local/bin
  pick-fuzzel           shared dmenu wrapper for every picker
brave/                  Wayland flags for Brave browser
btop/                   system monitor (uses terminal palette)
fastfetch/              login system info and ascii art
fish/                   shell config, aliases, flatpak dirs
fontconfig/             LCD subpixel hinting and CJK font rules
foot/                   terminal config and search keybinds
fuzzel/                 launcher appearance and typography
git/                    git defaults (user identity is not tracked)
gtk/                    GTK3/GTK4 settings and cursor inheritance
mpv/                    video player config and hardware acceleration
pipewire/               audio quirks for browsers and voice apps
starship/               prompt configuration
sway/                   Sway window manager config and helper scripts
  host.conf.example     template for machine-specific hardware overrides
  scripts/              desktop helpers (brightness, recorder, screenshot, etc.)
systemd/                user units (tmux session)
thunar/                 Thunar custom context actions
tmux/                   tmux status and keybindings
wal/                    pywal templates for every themed program
xdg/                    MIME defaults, user dirs, Wayland env
xdg-desktop-portal-wlr/ screen sharing portal
install.sh              stow wrapper and dependency check
LICENSE                 MIT
```

## Requirements

Install the desktop ecosystem on Arch Linux:

```bash
sudo pacman -S sway swaybg swaylock swayosd foot fuzzel fish starship tmux \
  thunar mako wl-clipboard cliphist grim slurp wf-recorder brightnessctl \
  playerctl pipewire wireplumber networkmanager jq imagemagick ddcutil \
  papirus-icon-theme ttf-jetbrains-mono-nerd polkit-gnome mpv \
  ffmpegthumbnailer xdg-desktop-portal-wlr stow eza bat fastfetch \
  adw-gtk-theme pacman-contrib btop
yay -S python-pywal16
```

Two optional assets are not packaged:

- **Cursor**: the configuration names `Doro`. Put any XCursor theme in
  `~/.local/share/icons/<name>` and update the theme name in
  `gtk/.config/gtk-3.0/settings.ini`, `gtk-4.0/settings.ini`, and
  `gtk/.icons/default/index.theme`.
- **Wallpapers**: `Super+Shift+w` opens `~/pictures/wallpapers` in Thunar.
  Right-click an image and pick **Set as Wallpaper**.

## Install

```bash
git clone https://github.com/shironxn/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` verifies requirements, prepares directories, and links each
package into `$HOME` with `stow -R`. It never modifies untracked files.

Bootstrap your pywal palette on first run:

```bash
wal -i ~/pictures/wallpapers/<your-wallpaper.jpg>
~/.config/sway/scripts/wal-theme.sh -R
```

Then reload Sway (`Super+Shift+c` or `swaymsg reload`).

## Machine-Specific Setup (`host.conf`)

By default, Sway auto-detects connected outputs and assigns workspaces
dynamically. To arrange multi-monitor layouts, pin workspaces, or apply device
quirks, copy the example template:

```bash
cp ~/.config/sway/host.conf.example ~/.config/sway/host.conf
```

`host.conf` is ignored by git (`.gitignore`). Example directives:

```sway
# Position dual monitors:
output eDP-1 scale 1.0 subpixel rgb position 1920 0
output HDMI-A-2 scale 1.0 subpixel rgb position 0 0

# Pin workspaces to specific screens:
workspace 1 output HDMI-A-2 eDP-1
workspace 7 output eDP-1 HDMI-A-2

# Device quirks or gaming mouse sensitivity:
input "0000:0000:Example_Mouse" {
    accel_profile flat
    pointer_accel 0
}
```

## Optional Personal Configs

A few files fit specific desktop choices and can be adjusted or removed:

| Path | Purpose |
|---|---|
| `git/.config/git/config` | Global git defaults; set your name/email in `~/.gitconfig` |
| `xdg/.config/mimeapps.list` | Default applications (includes Brave, Loupe, Evince) |
| `brave/.config/brave-flags.conf` | Wayland flags for the Brave browser |
| `fontconfig/.config/fontconfig/conf.d/` | Japanese font preference rule (uses Noto Sans CJK JP; install `noto-fonts-cjk` if needed) |
| `gtk/.config/gtk-{3.0,4.0}`, `gtk/.icons` | Theme, icon, and cursor names (`adw-gtk3-dark`, `Papirus-Dark`, `Doro`) |
| `btop/.config/btop/btop.conf` | Full layout; disk filters and process sorting are tuned per machine |
| `fastfetch/.config/fastfetch/` | Personal ASCII logo, printed on every interactive shell |

## Local Overrides

Customize without editing this repository. Three hooks are loaded last, so
anything set there wins:

| Hook | Loaded by |
|---|---|
| `~/.gitconfig.local` | `git/config` (`[include]`) |
| `~/.config/fish/config.local.fish` | `fish/config.fish` |
| `~/.config/sway/host.conf` | `sway/config` |

Files under `xdg/` have no override hook and take effect on the next login.
Review `mimeapps.list` (sets Brave as the default browser, plus a Roblox
handler) and `user-dirs.dirs` (lowercase `~/downloads`, `~/pictures`,
`~/videos`) before installing, or delete them from `$HOME` afterwards if you
prefer your own defaults.

## Not Tracked

Deliberately left out of the repository:

| Path | Why |
|---|---|
| `~/.config/sway/host.conf` | Real monitor layout, device IDs, and per-machine quirks |
| `~/.config/fish/conf.d/secrets.fish` | API keys and tokens |
| `~/.config/fish/fish_variables` | Machine-local shell state |
| `~/.gitconfig` | Identity |
| `~/.cache/wal/*` | Generated palette, rebuilt from the wallpaper |

## Keybindings

`Super` is the Mod4 (Windows/Command) key.

### Basics

| Key | Action |
|---|---|
| `Super+Return` | Terminal (`foot`) |
| `Super+d` | Application launcher (`fuzzel`) |
| `Super+Tab` | Window switcher |
| `Super+Shift+q` | Close window |
| `Super+Shift+c` | Reload Sway config |
| `Super+Shift+e` | Exit Sway |
| `Super+/` | Keybinding cheatsheet popup |

### Utilities

| Key | Action |
|---|---|
| `Super+Shift+s`, `Print` | Screenshot (Area, Window, or Display) |
| `Super+Shift+r` | Screen recorder with desktop audio |
| `Super+Shift+w` | Open `~/pictures/wallpapers` in Thunar (right-click → Set as Wallpaper) |
| `Super+Shift+v` | Clipboard history |
| `Super+Alt+v` | Clear clipboard history |
| `Super+Shift+BackSpace` | Lock screen (`swaylock`) |
| `Super+Shift+Delete` | Power menu (Lock, Suspend, Reboot, Shutdown) |

### Window Management

| Key | Action |
|---|---|
| `Super+h/j/k/l`, `Super+arrows` | Move focus |
| `Super+Shift+h/j/k/l` | Move window |
| `Super+o` | Cycle focus to the next display |
| `Super+Shift+o` | Move container to the next display |
| `Super+b`, `Super+v` | Split horizontal, vertical |
| `Super+s`, `Super+w`, `Super+e` | Stacking, tabbed, toggle split |
| `Super+f` | Fullscreen toggle |
| `Super+Shift+space` | Floating toggle |
| `Super+p` | Sticky toggle |
| `Super+space` | Focus toggle (tiling ↔ floating) |
| `Super+a` | Focus parent container |
| `Super+r` then `h/j/k/l` | Resize mode |
| `Super+Shift+minus`, `Super+minus` | Move to / show scratchpad |

### Hardware Keys

- **Volume / Mute**: XF86Audio keys via `swayosd-client`
- **Microphone Mute**: Hardware mic toggle with status bar indicator
- **Brightness**: Internal backlight via `swayosd-client`, external via `ddcutil`
- **Keyboard Backlight**: ThinkPad keyboard backlight stepped through OSD
- **Media**: Play/pause, next, previous via `playerctl`
- **Lid**: closing the lid locks the screen, then logind suspends (system default)

## Theming

Wallpaper selection triggers `sway/scripts/wal-theme.sh`, generating pywal
palettes and reloading running clients:

| Target | Template | Applied Component |
|---|---|---|
| `colors-sway` | Sway variables | Borders, bar, workspace buttons |
| `colors-foot.ini` | foot | Terminal 16-color palette |
| `colors-fuzzel.ini` | fuzzel | App launcher & dmenu dialogs |
| `colors-mako` | mako | Notification popups |
| `colors-gtk.css` | GTK3 | GTK applications & Thunar |
| `colors-swaylock` | swaylock | Lockscreen ring & indicators |
| `style-swayosd.css` | SwayOSD | Volume & brightness indicators |

Lock screen uses a frosted, blurred version of the wallpaper generated
proportionally to the active display resolution. `btop` uses its builtin `TTY`
theme to follow terminal colors without generation.

## Status Bar

`sway/scripts/status.sh` formats the top bar into grouped modules:

```
REC 00:42  │  󰎆 Artist - Track  │  󰔏 54°C · 󰍛 8.2G · 󰏗 13  │  󰖩 · 󰖀 45% · 󰍭 · 󰂀 78%  │  󰃭 28 Oct · 19:51
```

- **Transient on the left**: Screen recording timer and now-playing media grow
  dynamically without displacing hardware metrics or the clock.
- **Hardware sensors**: Automatically discovers package/core thermal sensors
  across Intel, AMD, and ARM architectures.
- **Contextual indicators**: Microphone mute glyph appears only when muted;
  battery icon scales through 7 charge tiers.
- **Atomic caching**: Metric updates run asynchronously with non-blocking locks
  to ensure zero frame stutter.

## License

MIT. See [LICENSE](LICENSE).
