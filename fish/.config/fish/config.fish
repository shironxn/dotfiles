set -g fish_greeting

if test -f ~/.cache/wal/colors.fish
    cat ~/.cache/wal/colors.fish | source
end

starship init fish | source

alias ls="eza --icons"
alias ll="eza -lah --icons"
alias cat="bat"

fastfetch
set -gx OPENCODE_EXPERIMENTAL_LSP_TOOL true
set -gx OPENCODE_ENABLE_EXA 1

# Hermes Agent — ensure ~/.local/bin and ~/bin are on PATH
fish_add_path "$HOME/.local/bin"
fish_add_path "$HOME/bin"

# Wakatime fish integration
function wakatime_heartbeat --on-event fish_postexec
    set -l entity (string escape -- (pwd))
    ~/bin/wakatime-cli --write --entity "$entity" --project (basename "$entity") --plugin "fish-shell" >/dev/null 2>&1 &
end
