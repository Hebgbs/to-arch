# Run `pacman -Qq` and grep a pattern quietly
grepPacmanQuery() { # $1 - Pattern to grep for in the output of `pacman -Qq`
	pacman -Qq | grep "$1" -q
}

# Remove a package if it matched `pacman -Qq`
removeIfMatched() { # $1 - Pattern
	grepPacmanQuery "$1" && pacman -Rsdd "$1" --noconfirm
	true
}

# Temporary directory to store all our stuff in
tmp_dir="$(mktemp -d)"

pacman -Syy neofetch micro vim --noconfirm
neofetch
printf "This is your current distro state.\n"

sudo pacman -Rdd garuda-hooks --noconfirm

if grepPacmanQuery pamac; then
	printf "\nDo you want to remove pamac?(Y/n)\n"
	read -rn 1 a
	case "$a" in
		[Nn]*) printf "Leaving pamac alone.\n" ;;
		*) pacman -Qq | grep pamac | xargs pacman -Rdd --noconfirm ;;
	esac
fi



(
	cd /etc/pacman.d
	rm mirrorlist
	# Get mirrorlist
	curl -o mirrorlist -sL 'https://archlinux.org/mirrorlist/?country=all&protocol=http&protocol=https&ip_version=4&ip_version=6'
	
	
	
	[ -f /etc/pacman.d/mirrorlist.pacnew ] && rm /etc/pacman.d/mirrorlist.pacnew
	[ -f /etc/pacman.conf.pacnew ] && rm /etc/pacman.conf.pacnew
	
	# Delete crappy unrecognized pacman option by Manjaro
	sed -i '/SyncFirst/d' /etc/pacman.conf
	sed -i '/HoldPkg/d' /etc/pacman.conf
	
	# Use $VISUAL instead?
	printf "==> Uncomment mirrors from your country.\nPress 1 for Nano, 2 for vim, 3 for vi, 4 for micro, or any other key for your default \$EDITOR.\n"
	read -rn 1 whateditor
	case "$whateditor" in
		"1") nano /etc/pacman.d/mirrorlist ;;
		"2") vim /etc/pacman.d/mirrorlist ;;
		"3") vi /etc/pacman.d/mirrorlist ;;
		"4") micro /etc/pacman.d/mirrorlist ;;
		*) $EDITOR /etc/pacman.d/mirrorlist ;;
	esac
	
	# Backup just in case
	cp /etc/pacman.d/mirrorlist "${tmp_dir}/mirrorlist"
)

# Manjaro uses a different mirrorlist package to identify from the Arch one.
pacman -Qq pacman-mirrors &>/dev/null && pacman -Qq | grep pacman-mirrors | xargs pacman -Rdd --noconfirm


# Get pacman, mirrorlist and lsb_release from website, not mirrors
pacman -U --overwrite \*  https://www.archlinux.org/packages/core/x86_64/pacman/download/ https://www.archlinux.org/packages/core/any/pacman-mirrorlist/download/ https://www.archlinux.org/packages/community/any/lsb-release/download/ --noconfirm

\mv -f "${tmp_dir}/mirrorlist" /etc/pacman.d/mirrorlist
# Do it again, because conf gets reset
sed -i '/SyncFirst/d' /etc/pacman.conf

# Change grub
sed -i '/GRUB_DISTRIBUTOR="Garuda"/c\GRUB_DISTRIBUTOR="Arch"' /etc/default/grub

# Following line enables multilib repository
sed -ie 's/#\(\[multilib\]\)/\1/;/\[multilib\]/,/^$/{//!s/^#//;}' /etc/pacman.conf

# Prevent HoldPkg error
sed -i '/HoldPkg/d' /etc/pacman.conf

# Purge Manjaro's software
pacman -Qq | grep garuda | xargs pacman -Rdd --noconfirm
pacman -Qq | grep plymouth | xargs pacman -Rdd --noconfirm
# KDE Plasma
pacman -Qq | grep sweet | xargs pacman -Rdd --noconfirm


###################
#TODO:Probably some kind of custom hook in manjarno.
#/usr/share/libalpm/hooks/*
###################
# -Syyyyyyyyyyuuuuuuuu calms me down
[ -f /etc/lsb-release ] && mv /etc/lsb-release /etc/lsb-release.bak
pacman -Syyu --overwrite \* bash lsb-release --noconfirm

# As Linus Torvalds said, nvidia, fück you
pacman -Qq | grep mhwd | xargs pacman -Rdd --noconfirm 2>/dev/null


pacman -Qq | grep latte | xargs pacman -Rdd --noconfirm 2>/dev/null

# Change computer's name if it's manjaro
if [ -f /etc/hostname ]; then
	sed -i '/garuda/c\Arch' /etc/hostname
	sed -i '/Garuda/c\Arch' /etc/hostname
fi

sed -i '/garuda/c\Arch' /etc/hosts
sed -i '/Garuda/c\Arch' /etc/hosts

printf "What kernel? Press 1 for linux, 2 for linux-lts.\n"
read -rn 1 whatkernel
case "$whatkernel" in
        "2") pacman -S linux-lts linux-lts-headers --noconfirm ;;
        *) pacman -S linux linux-headers --noconfirm ;;
esac

# Fück you nvidia
pacman -Qq | grep nvidia | xargs pacman -Rdd --noconfirm 2>/dev/null
if [ "$(lspci | grep -i nvidia)" ]; then
    pacman -S nvidia-dkms --noconfirm
fi

# Delete line that hides GRUB. Manjaro devs, do you think that noobs don't even know how to press enter?
sed -i '/GRUB_TIMEOUT_STYLE=hidden/d' /etc/default/grub

# Changes Manjaro GRUB theme. Manjaro doesn't have an option to install systemd-boot, Right? I'm just assuming you have a clean install of Manjaro.
if ! [ "$(bootctl is-installed | grep -i yes)" ]; then
	curl -fLs https://github.com/AdisonCavani/distro-grub-themes/releases/latest/download/arch.tar -o /tmp/arch.tar
	[ -d /boot/grub/themes/archlinux ] && rm -rf /boot/grub/themes/archlinux
	mkdir /boot/grub/themes/archlinux
	tar -xf /tmp/arch.tar -C /boot/grub/themes/archlinux
	sed -i '/GRUB_THEME=.*/c GRUB_THEME="/boot/grub/themes/archlinux/theme.txt"' /etc/default/grub
	# Generate GRUB stuff
	[ -f /boot/grub/grub.cfg ] && rm /boot/grub/grub.cfg
	[ -f /boot/grub/grub.cfg.new ] && rm /boot/grub/grub.cfg.new
	grub-mkconfig -o /boot/grub/grub.cfg

else 
    bootctl update
    printf "Systemd-boot users have to edit the updated the entries manually.\nYou're on your own, good luck, my friend."
fi
# Locale fix
# It scared the daylights out of me when I realized gnome-terminal won't start without this part
[ -f /etc/locale.conf.pacsave ] && \mv -f /etc/locale.conf.pacsave /etc/locale.conf
locale-gen



# Greeter bg remove (Doesn't really work idk why)
if [ -f /etc/lightdm/unity-greeter.conf ]; then
	sed -i '/background/d' /etc/lightdm/unity-greeter.conf
	sed -i '/default-user-image/d' /etc/lightdm/unity-greeter.conf
fi

if [ -f /etc/lightdm/lightdm-gtk-greeter.conf ]; then
	sed -i '/background/d' /etc/lightdm/lightdm-gtk-greeter.conf
	sed -i '/default-user-image/d' /etc/lightdm/lightdm-gtk-greeter.conf
fi

# I know... sorry...
if [ -f /etc/os-release ]; then
	sed -i 's/Garuda/Arch/g' /etc/os-release
	sed -i 's/ID=garuda/ID=arch/g' /etc/os-release
	sed -i 's/SUPPORT_URL=\"https:\/\/forum.garudalinux.org\"/SUPPORT_URL=\"https:\/\/bbs.archlinux.org\"/g' /etc/os-release
	sed -i 's/garudalinux/archlinux/g' /etc/os-release
	sed -i '/BUG_REPORT_URL/d' /etc/os-release
	sed -i 's/LOGO=garudalinux/LOGO=archlinux-logo/g' /etc/os-release
fi

[ -f /etc/issue ] && sed -i 's/Garuda/Arch/g' /etc/issue

# Screenfetch takes an eternity to run in VMs. I have no damn idea why.
neofetch
printf "Now it's Arch! Enjoy!\n"
printf "There could be some leftover Manjaro backgrounds and themes/settings,\nso you might have to tweak your desktop environment a bit.\n"

if grepPacmanQuery deepin-desktop-base; then
	printf "When you reboot, the theme will be changed to stock white but the font won't,\nso change it to dark again and it'll be fixed..\n"
	printf "And especially on VMs after login everything will be white.\nBlindly press on the middle of the screen and you'll be logged in.\n"
fi

if systemctl list-unit-files | grep enabled | grep -q sddm; then
	printf "You seem to run SDDM.\nMake sure you change the SDDM theme to something else like breeze because the default theme looks horrible!\n"
fi

if grepPacmanQuery i3; then
	pacman -S i3status i3blocks --noconfirm
fi

if [ -f /etc/lightdm/slick-greeter.conf ]; then
	sed -i '/background/d' /etc/lightdm/slick-greeter.conf
	sed -i '/default-user-image/d' /etc/lightdm/slick-greeter.conf
fi

if grepPacmanQuery gnome; then
	pacman -Qq | grep gnome-layout-switcher | xargs pacman -Rdd --noconfirm
fi

if grepPacmanQuery sway; then
	pacman -S dmenu --noconfirm
fi

# This file is known to exist in the gnome edition, but somehow vanishes after reboot.
# Still let's change it.
if [ -f /etc/arch-release ]; then
	sed -i '/Garuda/c\Arch' /etc/arch-release
fi



[ -f /.garuda-tools ] && rm -f /.manjaro-tools
[ -d /var/lib/pacman-mirrors ] && rm -rf /var/lib/pacman-mirrors
