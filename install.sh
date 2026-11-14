#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

die() { printf 'error: %s\n' "$1" >&2; exit 1; }

command -v stow >/dev/null 2>&1 ||
    die "GNU Stow is required (pacman -S stow, apt install stow)"

# Programs the configuration calls. Missing ones are reported, never installed.
required=(
    sway swaymsg swaybg swaylock swayosd-server swayosd-client foot fuzzel
    fish starship tmux mako thunar wl-copy wl-paste cliphist grim slurp
    wf-recorder brightnessctl playerctl pactl nmcli checkupdates jq magick
    ddcutil wal fastfetch mpv notify-send gsettings btop
)
missing=()
for cmd in "${required[@]}"; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if ((${#missing[@]})); then
    printf 'warning: not found in PATH: %s\n' "${missing[@]}" >&2
    printf '         see the Requirements section of the README\n\n' >&2
fi

packages=(
    bin brave btop fastfetch fish fontconfig foot fuzzel git gtk mpv
    pipewire portal starship sway systemd thunar tmux wal xdg
)

echo "==> preparing directories"
# Wallpapers is where Super+Shift+w opens and where wallpaper.sh looks a bare
# filename up, so it has to exist before the first theme is generated.
mkdir -p "$HOME/.config" "$HOME/.local/bin" \
    "$HOME/pictures/screenshots" "$HOME/pictures/wallpapers" \
    "$HOME/videos/recordings"

echo "==> setting script permissions"
chmod +x bin/.local/bin/pick-fuzzel sway/.config/sway/scripts/*.sh

echo "==> clearing paths stow cannot link over"
# A first login already creates these two files (xdg-utils and xdg-user-dirs
# write them), and stow aborts the whole package rather than replace a plain
# file. Keep the original next to the new symlink instead of deleting it.
for conflict in \
    "$HOME/.config/mimeapps.list" \
    "$HOME/.config/user-dirs.dirs"; do
    [ -e "$conflict" ] && [ ! -L "$conflict" ] || continue
    mv -- "$conflict" "$conflict.pre-dotfiles"
    echo "  -> kept the old $(basename "$conflict") as $conflict.pre-dotfiles"
done

echo "==> stowing"
# --no-folding keeps stow from replacing whole directories with symlinks. With
# folding, anything a program writes at runtime lands inside this repo instead
# of $HOME, so the working tree picks up machine state.
for pkg in "${packages[@]}"; do
    echo "  -> $pkg"
    stow -R --no-folding -t "$HOME" "$pkg" ||
        die "$pkg conflicts with an existing file above; move it aside and retry"
done

echo "==> validating sway config"
if command -v sway >/dev/null 2>&1; then
    sway -C >/dev/null 2>&1 ||
        die "sway rejected the config; run 'sway -C' to see the offending line"
fi

# Thunar rewrites uca.xml whenever an action is edited, replacing a stow
# symlink with a plain file, so it is copied rather than linked. Re-run this
# script after changing thunar/.config/Thunar/uca.xml.
mkdir -p "$HOME/.config/Thunar"
install -m 600 thunar/.config/Thunar/uca.xml "$HOME/.config/Thunar/uca.xml"

# Thunar ships its own "Set as wallpaper" action that only works on XFCE and
# GNOME. Under Sway it fails silently, and it sits next to the custom action
# below with an almost identical label, so image right-clicks look broken.
# Disable it once; a Thunar upgrade puts the file back and this is a no-op then.
wallpaper_plugin=/usr/lib/thunarx-3/thunar-wallpaper-plugin.so
if [ -f "$wallpaper_plugin" ] && [ -w "$(dirname "$wallpaper_plugin")" ]; then
    mv "$wallpaper_plugin" "$wallpaper_plugin.disabled"
    echo "  -> disabled Thunar's built-in wallpaper action"
elif [ -f "$wallpaper_plugin" ]; then
    echo "  * run this once with sudo to hide Thunar's duplicate wallpaper action:"
    echo "      sudo mv $wallpaper_plugin $wallpaper_plugin.disabled"
fi

echo
echo "==> next steps"
if [ ! -f "$HOME/.cache/wal/colors-sway" ]; then
    echo "  * no palette yet. Pick a wallpaper (Super+Shift+w) or run:"
    echo "      ~/.config/sway/scripts/wallpaper.sh -i ~/pictures/wallpapers/<image>"
fi
if ! git config --global user.email >/dev/null 2>&1; then
    echo "  * set your git identity: git config --global user.name/user.email"
fi
[ -d "$HOME/.local/share/icons/Doro" ] ||
    echo "  * the Doro cursor theme is not in this repo; install it or change the cursor name"
if [ ! -f "$HOME/.config/sway/host.conf" ]; then
    echo "  * for custom monitor positions, workspace pinning, or device quirks:"
    echo "      cp ~/.config/sway/host.conf.example ~/.config/sway/host.conf"
fi
echo "  * log out and back in, or run 'swaymsg reload'"
