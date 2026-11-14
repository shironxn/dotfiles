# dotfiles

My Sway setup on Arch Linux. A wallpaper sets the palette through pywal16, and
the bar, borders, terminal and GTK apps read their colours from it.

![Sway desktop](assets/preview.webp)

![Terminal](assets/terminal.webp)

![Terminal and file manager tiled](assets/split.webp)

## Packages

```bash
sudo pacman -S sway swaybg swaylock swayosd foot fuzzel fish starship tmux \
  thunar mako libnotify wl-clipboard cliphist grim slurp wf-recorder brightnessctl \
  playerctl pipewire wireplumber networkmanager jq imagemagick ddcutil \
  papirus-icon-theme ttf-jetbrains-mono-nerd polkit-gnome mpv mpv-mpris \
  ffmpegthumbnailer xdg-desktop-portal-wlr stow eza bat fastfetch \
  adw-gtk-theme pacman-contrib btop neovim
yay -S python-pywal16
```

Install `noto-fonts-cjk` too, for the Japanese fallback in fontconfig. The cursor
theme is `Doro`, expected in `~/.local/share/icons/Doro`. To use another one,
change `seat * xcursor_theme` in `config.d/input.conf` and `gtk-cursor-theme-name`
in `gtk-3.0/settings.ini` and `gtk-4.0/settings.ini`.

## Install

```bash
git clone https://github.com/shironxn/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
~/.config/sway/scripts/wallpaper.sh -i ~/pictures/wallpapers/<file.jpg>
```

The last line is also on the right-click menu in Thunar, as "Set as Wallpaper".

## Keys

`Super+/` lists every binding. The list is built from `keybinds.conf` when you
open it, so new bindings show up without editing a second file.

| Key | Action |
|---|---|
| `Super+Return` | foot |
| `Super+d` | launcher |
| `Super+Tab` | window switcher |
| `Super+/` | cheat sheet |
| `Print`, `Super+Shift+s` | screenshot |
| `Super+Shift+r` | screen recorder |
| `Super+Shift+v` | clipboard history |
| `Super+Shift+BackSpace` | lock |
| `Super+Shift+Delete` | power menu |

Volume, microphone mute, panel and keyboard backlight go through SwayOSD.
External monitor brightness uses `ddcutil` and the media keys use `playerctl`.
Closing the lid locks the screen, then logind suspends.

## Layout

Each top-level directory is a stow package that mirrors `$HOME`. `assets/` is the
exception and holds the screenshots above.

| Path | Contents |
|---|---|
| `sway/.config/sway/config` | palette, then `config.d/*`, then `/etc/sway/config.d/*`, then `host.conf` |
| `sway/.config/sway/scripts/` | `wallpaper.sh` builds the palette, `status.sh` feeds the bar, one job per other script |
| `wal/.config/wal/templates/` | pywal16 templates, output lands in `~/.cache/wal` |
| `local/.local/bin/pick-fuzzel` | wrapper every picker goes through |
| `systemd/`, `xdg-portal/`, `pipewire/` | user units, portal and pipewire config |

Overrides, credentials, generated caches, editor configs and media files are not
tracked. `btop.conf` needs one caveat: it ships with
`save_config_on_exit = false`, because btop writes detected hardware into that
file when it quits. Press `Ctrl+S` inside btop to keep a change.

## Local files

These are git-ignored and load after the tracked files. `install.sh` does not
create them, so add the ones you need:

- `~/.config/sway/host.conf` for monitors, workspaces and input devices, starting
  from `sway/.config/sway/host.conf.example`
- `~/.config/fish/config.local.fish`
- `~/.gitconfig.local`, which `git/.config/git/config` includes

Credentials go in `~/.config/fish/conf.d/secrets.fish`, also ignored. Nothing
tracked here is a secret, which is why the repo stays public.

## Uninstall

```bash
cd ~/dotfiles
for pkg in local brave btop fastfetch fish fontconfig foot fuzzel git gtk mpv \
    pipewire starship sway systemd thunar tmux wal xdg xdg-portal; do
    stow -D -t "$HOME" "$pkg"
done
```

`stow -D` only removes the links that point into this repo. Your own files stay,
and `~/.cache/wal` is untouched.

## Troubleshooting

- Bar and borders stay grey after a theme change: `~/.cache/wal/colors-sway` was
  not generated. Run `wallpaper.sh -R`, or `wallpaper.sh -i <image>` if there is
  no cached session yet.
- Every `wal` run fails after editing `wal/`: a template symlink points at a
  deleted file. Run `find ~/.config/wal/templates -xtype l -delete`.
- Colours are wrong after a pywal16 upgrade: `wal -c` clears the cache, then
  apply a wallpaper again.
- `foot` or `fuzzel` complain about a missing include: there is no palette on
  this machine yet.
- Sway will not start: `sway -C` names the offending line.
- External brightness does nothing: the monitor has no DDC/CI. Check
  `ddcutil detect`.

## License

MIT. See [LICENSE](LICENSE).
