#!/usr/bin/env bash
# Deploy this repository into $HOME with GNU Stow.
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

if ! command -v stow >/dev/null 2>&1; then
    echo "error: GNU Stow is required (pacman -S stow)" >&2
    exit 1
fi

packages=(
    bin fastfetch fish foot fuzzel git gtk mpv starship
    sway thunar tmux wal xdg xdg-desktop-portal-wlr
)

echo "==> preparing directories"
mkdir -p "$HOME/.config" "$HOME/.local/bin" \
    "$HOME/pictures/screenshots" "$HOME/videos/recordings"

echo "==> setting script permissions"
chmod +x bin/.local/bin/* sway/.config/sway/scripts/*

echo "==> stowing"
for pkg in "${packages[@]}"; do
    echo "  -> $pkg"
    stow -R -t "$HOME" "$pkg"
done

echo "==> done. Log out and back in, or run 'swaymsg reload'."
