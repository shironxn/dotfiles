# Fish shell configuration

set -g fish_greeting

if test -f ~/.cache/wal/colors.fish
    source ~/.cache/wal/colors.fish
end

starship init fish | source

alias ls="eza --icons=auto"
alias ll="eza -lah --icons=auto"
alias cat="bat"

if status is-interactive
    fastfetch
end

if command -q nvim
    set -gx EDITOR nvim
    set -gx VISUAL nvim
else if command -q nano
    set -gx EDITOR nano
    set -gx VISUAL nano
end
set -gx BROWSER brave
set -gx TERMINAL foot

fish_add_path "$HOME/.local/bin"

# Flatpak desktop entries and binaries
set -q XDG_DATA_DIRS; or set -gx XDG_DATA_DIRS /usr/local/share:/usr/share
if test -d /var/lib/flatpak/exports/share
    set -gx XDG_DATA_DIRS "/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share:$XDG_DATA_DIRS"
end

# Development and privacy defaults
test -d "$HOME/.local/share/go"; and set -gx GOPATH "$HOME/.local/share/go"
set -gx DISABLE_TELEMETRY 1
set -gx DO_NOT_TRACK 1

# Machine-local additions
if test -f ~/.config/fish/config.local.fish
    source ~/.config/fish/config.local.fish
end
