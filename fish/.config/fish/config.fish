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

set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx BROWSER brave
set -gx TERMINAL foot

fish_add_path "$HOME/.local/bin"

# Flatpak desktop entries and binaries
set -gx XDG_DATA_DIRS /var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share:/usr/local/share:/usr/share

# Pi agent: short-lived subagent caches cost more to write than to miss.
set -gx PI_CACHE_RETENTION long
set -gx PI_SUBAGENT_CACHE_RETENTION short

# Telemetry opt-out (the npx skills CLI defaults to on)
set -gx DISABLE_TELEMETRY 1
set -gx DO_NOT_TRACK 1
