function inbox
    set -l filename (date "+raw-%Y%m%d%H%M%S.md")
    set -l filepath "$HOME/Dev/obsidian/01 - Inbox/$filename"
    nvim "$filepath"
end
