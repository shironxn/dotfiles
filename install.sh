#!/usr/bin/env bash
# Link this repository into $HOME with GNU Stow.
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
    ddcutil wal python3 fastfetch mpv notify-send dconf gsettings
)
missing=()
for cmd in "${required[@]}"; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if ((${#missing[@]})); then
    printf 'warning: not found in PATH: %s\n' "${missing[*]}" >&2
    printf '         see the Requirements section of the README\n\n' >&2
fi

packages=(
    bin brave btop fastfetch fish fontconfig foot fuzzel git gtk mpv
    pipewire starship sway systemd thunar tmux wal xdg
    xdg-desktop-portal-wlr
)

echo "==> preparing directories"
mkdir -p "$HOME/.config" "$HOME/.local/bin" \
    "$HOME/pictures/screenshots" "$HOME/videos/recordings"

echo "==> setting script permissions"
chmod +x bin/.local/bin/* sway/.config/sway/scripts/*

echo "==> stowing"
for pkg in "${packages[@]}"; do
    echo "  -> $pkg"
    stow -R -t "$HOME" "$pkg" ||
        die "$pkg conflicts with an existing file above; move it aside and retry"
done

echo
echo "==> next steps"
if [ ! -f "$HOME/.cache/wal/colors-sway" ]; then
    echo "  * no palette yet. Pick a wallpaper (Super+Shift+w) or run:"
    echo "      wal -i /path/to/wallpaper.jpg"
    echo "      ~/.config/sway/scripts/wal-theme.sh -R"
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
