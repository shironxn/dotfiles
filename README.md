# dotfiles

Sway desktop on Arch Linux. Wallpapers drive the palette via pywal16.

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
- `noto-fonts-cjk` for Japanese glyph fallback in fontconfig.
- `Doro` cursor theme in `~/.local/share/icons/Doro` (or edit `appearance.conf`,
  GTK settings, and `install.sh` for your own).

## Install

```bash
git clone https://github.com/shironxn/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

Generate the initial palette:

```bash
~/.config/sway/scripts/wallpaper.sh ~/pictures/wallpapers/<wallpaper.jpg>
```

You can also right-click any image in Thunar and choose **Set as Wallpaper**.

## Keybindings

Press `Super+/` for the searchable cheatsheet generated from `keybinds.conf`.

| Key | Action |
|---|---|
| `Super+Return` | Terminal (`foot`) |
| `Super+d` | Application launcher |
| `Super+Tab` | Window switcher across workspaces |
| `Super+/` | Keybinding cheatsheet |
| `Super+Shift+s`, `Print` | Screenshot (area, window, or display) |
| `Super+Shift+r` | Screen recorder with desktop audio |
| `Super+Shift+w` | Wallpapers folder in Thunar |
| `Super+Shift+v` | Clipboard history |
| `Super+Shift+BackSpace` | Lock screen |
| `Super+Shift+Delete` | Power menu |

Hardware keys: volume, microphone mute, panel backlight, keyboard backlight
(via SwayOSD), external display brightness (via `ddcutil`), and media control
(via `playerctl`). Closing the laptop lid locks the screen and suspends.

## Overrides

Three git-ignored files load last for machine-specific settings:

- `~/.config/sway/host.conf` (monitors, workspaces, input devices; see
  `sway/.config/sway/host.conf.example`)
- `~/.config/fish/config.local.fish`
- `~/.gitconfig.local`

## License

MIT. See [LICENSE](LICENSE).
