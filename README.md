# shironxn's dotfiles

**Arch Linux · Sway · Fish · Foot · Fuzzel · Pywal · GNU Stow**

A clean, minimal, lightweight Wayland desktop environment configured for high productivity and zero bloat.

---

## 📸 Overview

* **OS:** [Arch Linux](https://archlinux.org/)
* **WM:** [Sway](https://swaywm.org/) (i3-compatible Wayland compositor)
* **Shell:** [Fish](https://fishshell.com/) with [Starship](https://starship.rs/)
* **Terminal:** [Foot](https://codeberg.org/dnkl/foot) (lightweight, DPI-tuned Wayland terminal)
* **Launcher:** [Fuzzel](https://codeberg.org/dnkl/fuzzel) (Wayland-native fuzzy application runner)
* **Theming:** Dynamic wallpaper colors via [Pywal16](https://github.com/eylles/pywal16)
* **Notifications:** [Mako](https://github.com/emersion/mako)
* **OSD:** [SwayOSD](https://github.com/ErikReider/SwayOSD) (volume, brightness, mic overlay)
* **Font:** JetBrains Mono Nerd Font
* **Icons:** Papirus-Dark

---

## 📂 Repository Structure

Managed declaratively with **[GNU Stow](https://www.gnu.org/software/stow/)**:

```text
dotfiles/
├── bin/                       # Scripts in ~/.local/bin/ (menu-launcher, pick-fuzzel)
├── environment/               # Wayland environment variables (~/.config/environment.d)
├── fastfetch/                 # Fastfetch system info & ASCII art
├── fish/                      # Fish shell config & aliases
├── foot/                      # Foot terminal emulator config
├── fuzzel/                    # Fuzzel application launcher config
├── git/                       # Git user configuration
├── gtk/                       # GTK 2/3/4 settings (Adwaita Dark + Papirus)
├── pkg-lists/                 # Pacman, AUR, and Flatpak package backups
├── starship/                  # Clean Starship prompt
├── sway/                      # Modular Sway configs & desktop helper scripts
├── thunar/                    # Thunar file manager custom actions
├── tmux/                      # Minimalist 45-line Tmux configuration
├── wal/                       # Pywal color templates (SSOT for dynamic theming)
├── xdg/                       # Default MIME associations & user directories
├── xdg-desktop-portal-wlr/    # Portal configuration for screen sharing
└── install.sh                 # Single-command Stow deployment script
```

---

## 🎨 Dynamic Wallpaper Theming

Wallpaper changes dynamically re-theme the desktop using Pywal templates:

* **Sway WM borders & bar** (`colors-sway`)
* **Foot Terminal** (`colors-foot.ini`)
* **Fuzzel Launcher** (`colors-fuzzel.ini`)
* **Mako Notifications** (`colors-mako`)
* **Swaylock** (`colors-swaylock`)
* **SwayOSD** (`style-swayosd.css`)

### Switching Wallpaper

Press `$mod+Shift+w` to open the wallpaper picker with live preview, or run:

```bash
~/.config/sway/scripts/wal-theme.sh -i /path/to/image.jpg
```

---

## 🚀 Installation

### 1. Prerequisites

Make sure you have `git` and `stow` installed:

```bash
sudo pacman -S git stow
```

### 2. Clone and Deploy

```bash
git clone https://github.com/shironxn/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` uses `stow` to symlink all configurations to your `$HOME` directory.

---

## ⌨️ Essential Keybindings

| Keybinding | Action |
|---|---|
| `Super + Enter` | Open Terminal (`foot`) |
| `Super + d` | App Launcher (`fuzzel`) |
| `Super + Shift + q` | Close focused window |
| `Super + Shift + s` or `Print` | Interactive Screenshot (`slurp` + `grim`) |
| `Super + Shift + w` | Wallpaper Picker (GTK3 preview + Pywal) |
| `Super + Shift + v` | Clipboard History (`cliphist`) |
| `Super + Shift + BackSpace` | Lock Screen (`swaylock`) |
| `Super + Shift + Delete` | Power Menu (Logout, Suspend, Reboot, Shutdown) |
| `Super + /` | Searchable Keybindings Cheatsheet |
| `Super + b` / `Super + v` | Split Horizontal / Vertical |
| `Super + f` | Toggle Fullscreen |
| `Super + Shift + Space` | Toggle Floating |

---

## 📜 License

MIT © [shironxn](https://github.com/shironxn)
