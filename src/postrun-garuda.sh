# KDE Plasma theme switch to default (user mode)
if pacman -Qq | grep -q plasma-desktop; then
	/usr/lib/plasma-changeicons breeze-dark 2>/dev/null
	lookandfeeltool --apply --resetLayout "org.kde.breezedark.desktop" 2>/dev/null
fi

# Deletes sway config cuz sway edition saves its configs in a packages and sway gets borked after deleteing those.
# And yes sway will look like plain i3.
if pacman -Qq | grep -q sway; then
	workdir="$(pwd)"
	rm -rf ~/.config/sway
	mkdir ~/.config/sway
	cd ~/.config/sway
	curl -o config -fLs https://raw.githubusercontent.com/swaywm/sway/master/config.in
	sed -i '/alacritty/c\foot' ~/.config/sway/config
	sed -i '/Wallpaper/d' ~/.config/sway/config
	cd "${workdir}"
	# # I know this part is extremely hacky and weird, but chsh doesn't change foots shell.
	#echo "clear;exec bash" >> ~/.zshrc
fi
# Some i3 MaNjArO removal.
if pacman -Qq | grep -q i3; then
	sed -i '/nitrogen/d' ~/.i3/config 2>/dev/null
fi
# There lurks a disgusting application residue in you ~/.config...
# The dreaded name of the package is matray, and it literally sprays your screen with Manjaro news and ads.
# It is seen in the KDE edition.
[ -d $HOME/.config/matray ] && rm -rf ~/.config/matray
[ -f $HOME/.config/autostart/manjaro-hello.desktop ] && rm -f ~/.config/autostart/manjaro-hello.desktop
# Reboot if you want.
#NO FISH! DO NOT USE FISH! IT WILL DAMAGE YOUR UNIX SKILLS PERMANENTLY!
chsh -s /bin/bash
printf "Would you like to reboot? Make sure you have read the above carefully! (y/N)"
read -r reboot
#Thanks to YTG1234 for this line.
# If we're already using Bash (#!/usr/bin/env bash), why not make use of its neat features
[ "$(tr '[:upper:]' '[:lower:]' <<< "$reboot")" = "y" ] && reboot
