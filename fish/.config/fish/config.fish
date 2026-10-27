# ─── Fish Config — Minimal ───

set -g fish_greeting

# Pywal dynamic colors (if available)
if test -f ~/.cache/wal/colors.fish
    source ~/.cache/wal/colors.fish
end

# Starship prompt
starship init fish | source

# Aliases
alias ls="eza --icons=auto"
alias ll="eza -lah --icons=auto"
alias cat="bat"

# Fastfetch (system info on terminal open)
fastfetch

# Default applications
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx BROWSER brave
set -gx TERMINAL foot

# Local bin
fish_add_path "$HOME/.local/bin"
set -gx XDG_DATA_DIRS /var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share:/usr/local/share:/usr/share
set -gx PI_CACHE_RETENTION long
# Subagent hidup <5 menit; cache 1 jam tak sempat kebaca dan tulisnya 2x lebih mahal.
set -gx PI_SUBAGENT_CACHE_RETENTION short

# Telemetry opt-out (npx skills CLI default ON)
set -gx DISABLE_TELEMETRY 1
set -gx DO_NOT_TRACK 1


