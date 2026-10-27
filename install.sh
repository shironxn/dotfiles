#!/usr/bin/env bash
# dotfiles installer — GNU Stow declarative deployment
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

# Check prerequisite
if ! command -v stow >/dev/null 2>&1; then
    echo "==> Error: GNU Stow is required." >&2
    echo "    Install with: sudo pacman -S stow" >&2
    exit 1
fi

echo "==> [1/3] Preparing target directories..."
mkdir -p "$HOME/.config" "$HOME/.local/bin"

echo "==> [2/3] Setting script permissions..."
chmod +x bin/.local/bin/* 2>/dev/null || true
chmod +x sway/.config/sway/scripts/* 2>/dev/null || true

# Packages to stow
PACKAGES=(
    bin
    fastfetch
    fish
    foot
    fuzzel
    git
    gtk
    starship
    sway
    thunar
    tmux
    wal
    xdg
    xdg-desktop-portal-wlr
)

echo "==> [3/3] Stowing packages to $HOME..."
for pkg in "${PACKAGES[@]}"; do
    if [ -d "$pkg" ]; then
        echo " -> Stowing $pkg"
        stow --adopt -v -R -t "$HOME" "$pkg"
    fi
done

echo "==> All packages stowed successfully!"
echo "==> Run 'swaymsg reload' or log in to your Sway session."
