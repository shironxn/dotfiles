#!/bin/sh
# Session menu: logout, suspend, reboot, shutdown, lock.
set -eu

choice=$(printf 'Logout\0icon\037system-log-out\nSuspend\0icon\037system-suspend\nReboot\0icon\037system-reboot\nShutdown\0icon\037system-shutdown\nLock\0icon\037system-lock-screen' |
  pick-fuzzel " power ")

case "$choice" in
Logout) swaymsg exit ;;
Suspend) systemctl suspend ;;
Reboot) systemctl reboot ;;
Shutdown) systemctl poweroff ;;
Lock) swaylock ;;
esac
