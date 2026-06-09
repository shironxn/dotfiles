#!/bin/bash
# Auto-generated backup script by Hermes

DOTFILES_DIR="$HOME/dotfiles"
cd "$DOTFILES_DIR" || exit 1

# Update package lists
pacman -Qqe > pkg-lists/pacman-native.txt
yay -Qqm > pkg-lists/aur-packages.txt
flatpak list --columns=application > pkg-lists/flatpak-apps.txt

# Sync configs (using cp -r)
cp -r ~/.config/sway/ sway/.config/
cp -r ~/.config/fish/ fish/.config/
cp -r ~/.config/foot/ foot/.config/
cp -r ~/.config/fuzzel/ fuzzel/.config/
cp -r ~/.config/nvim/ nvim/.config/
cp -r ~/.config/lazygit/ lazygit/.config/
cp -r ~/.config/fastfetch/ fastfetch/.config/
cp -r ~/.config/yay/ yay/.config/
cp -r ~/.config/wal/ wal/.config/
cp -r ~/.config/avizo/ avizo/.config/
cp ~/.gitconfig gitconfig/.gitconfig

# Git commit with Conventional Commits logic
if [[ -n $(git status -s) ]]; then
    git add .
    
    # Logic for commit message prefix
    if git diff --cached --name-only | grep -q "pkg-lists/"; then
        MSG="feat(pkg): update system package lists"
    elif git diff --cached --name-only | grep -q ".config/"; then
        MSG="chore(config): sync desktop configurations"
    else
        MSG="chore: maintenance sync $(date +\"%Y-%m-%d\")"
    fi

    git commit -m "$MSG"
    git push origin master
else
    echo "Nothing to commit."
fi