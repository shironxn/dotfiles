#!/bin/sh
# Application launcher ($mod+d). Adds the flatpak export dirs that Sway does
# not inherit, so flatpak entries show up in fuzzel.
case ":$XDG_DATA_DIRS:" in
*":/var/lib/flatpak/exports/share:"*) ;;
*) export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}" ;;
esac

exec fuzzel "$@"
