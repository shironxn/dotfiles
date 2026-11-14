# dotfiles

Sway on Arch Linux. The wallpaper picks the palette through pywal16 and the bar,
borders, terminal and GTK apps follow it.

![Sway desktop](assets/preview.webp)

![Terminal](assets/terminal.webp)

![Terminal and file manager tiled](assets/split.webp)

## Packages

```bash
sudo pacman -S sway swaybg swaylock swayosd foot fuzzel fish starship tmux \
  thunar mako libnotify wl-clipboard cliphist grim slurp wf-recorder brightnessctl \
  playerctl pipewire wireplumber networkmanager jq imagemagick ddcutil \
  papirus-icon-theme ttf-jetbrains-mono-nerd polkit-gnome mpv \
  ffmpegthumbnailer xdg-desktop-portal-wlr stow eza bat fastfetch \
  adw-gtk-theme pacman-contrib btop neovim
yay -S python-pywal16
```

Also install `noto-fonts-cjk` for the Japanese fallback in fontconfig, and put a
`Doro` cursor theme in `~/.local/share/icons/Doro`. For a different cursor,
change `seat * xcursor_theme` in `config.d/input.conf` and `gtk-cursor-theme-name`
in `gtk-3.0/settings.ini` and `gtk-4.0/settings.ini`.

## Install

```bash
git clone https://github.com/shironxn/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
~/.config/sway/scripts/wallpaper.sh -i ~/pictures/wallpapers/<file.jpg>
```

Right-clicking an image in Thunar and choosing **Set as Wallpaper** does what the
last line does.

## Keys

`Super+/` opens a searchable list built from `keybinds.conf`, so it cannot fall
out of date.

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

Volume, microphone mute, panel and keyboard backlight go through SwayOSD,
external monitor brightness through `ddcutil`, media keys through `playerctl`.
Closing the lid locks the screen, and logind suspends.

## Layout

Each top-level directory is a stow package that mirrors `$HOME`. `assets/` holds
the screenshots above.

| Path | Contents |
|---|---|
| `sway/.config/sway/config` | palette, then `config.d/*`, then `/etc/sway/config.d/*`, then `host.conf` |
| `sway/.config/sway/scripts/` | `wallpaper.sh` builds the palette, `status.sh` feeds the bar, one job per other script |
| `wal/.config/wal/templates/` | pywal16 templates, output lands in `~/.cache/wal` |
| `local/.local/bin/pick-fuzzel` | wrapper every picker goes through |
| `systemd/`, `xdg-portal/`, `pipewire/` | user units, portal and pipewire config |

Only text that would be identical on a freshly installed machine is tracked.
Machine-specific overrides, credentials, generated caches, editor configs and
media files stay out. `btop.conf` is tracked with `save_config_on_exit = false`
because btop would otherwise write detected hardware into it on exit, so use
`Ctrl+S` inside btop if you want a change to stick.

## Local files

Git-ignored files that load last. `install.sh` creates none of them, so write the
ones you need:

- `~/.config/sway/host.conf` for monitors, workspaces and input devices, starting
  from `sway/.config/sway/host.conf.example`
- `~/.config/fish/config.local.fish`
- `~/.gitconfig.local`, which `git/.config/git/config` includes

Credentials belong in `~/.config/fish/conf.d/secrets.fish`, also git-ignored.
Nothing tracked here is a secret, which is why the repo is public.

## Uninstall

```bash
cd ~/dotfiles
for pkg in local brave btop fastfetch fish fontconfig foot fuzzel git gtk mpv \
    pipewire starship sway systemd thunar tmux wal xdg xdg-portal; do
    stow -D -t "$HOME" "$pkg"
done
```

`stow -D` removes only the links that point into this repo. Files of your own
stay, and `~/.cache/wal` is left alone.

## Troubleshooting

- Bar and borders stay grey after a theme change: `~/.cache/wal/colors-sway` was
  not generated, run `wallpaper.sh -R`, or `wallpaper.sh -i <image>` when there
  is no cached session yet.
- Every `wal` run fails after editing `wal/`: a template symlink points at a
  deleted file, run `find ~/.config/wal/templates -xtype l -delete`.
- Colours are wrong after a pywal16 upgrade: `wal -c` clears the cache, then
  apply a wallpaper again.
- `foot` or `fuzzel` complain about a missing include: there is no palette on
  this machine yet.
- Sway will not start: `sway -C` names the offending line.
- External brightness does nothing: the monitor has no DDC/CI, check `ddcutil detect`.

## License

MIT. See [LICENSE](LICENSE).
