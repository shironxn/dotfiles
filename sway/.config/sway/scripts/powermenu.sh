#!/bin/sh

selected=$(printf "Logout\000icon\037system-log-out\nSuspend\000icon\037system-suspend\nReboot\000icon\037system-reboot\nShutdown\000icon\037system-shutdown\nLock\000icon\037system-lock-screen" | fuzzel -d -p "Power: " -i)

case "$selected" in
    *Logout)
        swaymsg exit
        ;;
    *Suspend)
        systemctl suspend
        ;;
    *Reboot)
        systemctl reboot
        ;;
    *Shutdown)
        systemctl poweroff
        ;;
    *Lock)
        swaylock
        ;;
esac
