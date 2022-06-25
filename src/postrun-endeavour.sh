# KDE Plasma theme switch to default (user mode)
if pacman -Qq | grep -q plasma-desktop; then
	/usr/lib/plasma-changeicons breeze-dark 2>/dev/null
	lookandfeeltool --apply "org.kde.breezedark.desktop" 2>/dev/null
fi
[ -f $HOME/.config/i3/config ] && sed -i '/endeavouros-i3wm-setup/d' ~/.config/i3/config
printf "Would you like to reboot? (y/N)"
read -r reboot
#Thanks to YTG1234 for this line.
# If we're already using Bash (#!/usr/bin/env bash), why not make use of its neat features
[ "$(tr '[:upper:]' '[:lower:]' <<< "$reboot")" = "y" ] && reboot
