# Run `pacman -Qq` and grep a pattern quietly
grepPacmanQuery() { # $1 - Pattern to grep for in the output of `pacman -Qq`
	pacman -Qq | grep "$1" -q
}

# Remove a package if it matched `pacman -Qq`
removeIfMatched() { # $1 - Pattern
	grepPacmanQuery "$1" && pacman -Rsdd "$1" --noconfirm
	true
}

pacman -Syy neofetch --noconfirm
neofetch
printf "This is your current distro state.\n"
tmp_dir="$(mktemp -d)"

rm -f /usr/share/libalpm/hooks/eos*

#https://bbs.archlinux.org/viewtopic.php?id=183737
LANG=C sudo pacman -Rcns $(pacman -Sl endeavouros | grep '\[installed\]' | cut -f2 -d' ') --noconfirm

if [ "$(grep '\[endeavouros\]' /etc/pacman.conf)" ]; then
	sudo sed -ie '/\[endeavouros\]/,+2d' /etc/pacman.conf
fi

[ -f /etc/pacman.d/endeavouros-mirrorlist ] && rm /etc/pacman.d/endeavouros-mirrorlist	
	
sed -i '/SyncFirst/d' /etc/pacman.conf
sed -i '/HoldPkg/d' /etc/pacman.conf

# Change computer's name if it's manjaro
if [ -f /etc/hostname ]; then
	sed -i '/endeavourOS/c\Arch' /etc/hostname
	sed -i '/EndeavourOS/c\Arch' /etc/hostname
	sed -i '/endeavour/c\Arch' /etc/hostname
	sed -i '/Endeavour/c\Arch' /etc/hostname
fi

sed -i '/endeavourOS/c\Arch' /etc/hosts
sed -i '/EndeavourOS/c\Arch' /etc/hosts
sed -i '/endeavour/c\Arch' /etc/hosts
sed -i '/Endeavour/c\Arch' /etc/hosts

if [ -f /etc/os-release ]; then
	sed -i 's/EndeavourOS/Arch Linux/g' /etc/os-release
	sed -i 's/ID=endeavouros/ID=arch/g' /etc/os-release
	sed -i 's/https:\/\/endeavouros\.com/https:\/\/archlinux\.org/g' /etc/os-release
	sed -i 's/https:\/\/discovery\.endeavouros\.com/https:\/\/archlinux\.org/g' /etc/os-release
	sed -i 's/SUPPORT_URL='"'"'https:\/\/forum\.endeavouros\.com'"'"'/SUPPORT_URL='"'"'https:\/\/bbs\.archlinux\.org'"'"'/g' /etc/os-release
	sed -i 's/BUG_REPORT_URL='"'"'https:\/\/forum\.endeavouros\.com.*'"'"'/SUPPORT_URL='"'"'https:\/\/bugs\.archlinux\.org'"'"'/g' /etc/os-release
fi

[ -f /etc/issue ] && sed -i 's/EndeavourOS/Arch/g' /etc/issue
pacman -Syyu --overwrite \* lsb-release --noconfirm

sed -i '/GRUB_DISTRIBUTOR="EndeavourOS"/c\GRUB_DISTRIBUTOR="Arch"' /etc/default/grub
if ! [ "$(bootctl is-installed | grep -i yes)" ]; then
	curl -fLs https://github.com/AdisonCavani/distro-grub-themes/releases/latest/download/arch.tar -o /tmp/arch.tar
	[ -d /boot/grub/themes/archlinux ] && rm -rf /boot/grub/themes/archlinux
	mkdir /boot/grub/themes/archlinux
	tar -xf /tmp/arch.tar -C /boot/grub/themes/archlinux
	sed -i '/GRUB_THEME=/c GRUB_THEME="/boot/grub/themes/archlinux/theme.txt"' /etc/default/grub
	# Generate GRUB stuff
	[ -f /boot/grub/grub.cfg ] && rm /boot/grub/grub.cfg
	[ -f /boot/grub/grub.cfg.new ] && rm /boot/grub/grub.cfg.new
	grub-mkconfig -o /boot/grub/grub.cfg

else 
    bootctl update
    printf "Systemd-boot users have to edit the updated the entries manually.\nYou're on your own."
fi

[ -f /etc/locale.conf.pacsave ] && \mv -f /etc/locale.conf.pacsave /etc/locale.conf
locale-gen

neofetch
printf "Now it's Arch! Enjoy!\n"
