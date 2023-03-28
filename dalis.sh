#! /bin/bash 

# This is an arch Linux install script that is as minimal as possible.
# © 2023 David Becker 
#
# ***LICENSE*** 
# License: MIT. See it here: https://raw.githubusercontent.com/simpyll/dalis/main/LICENSE
# 
# ***IMPORTANT*** 
# This script assumes you are connected to the internet. 
# You can do so directly by using an ethernet cable (It is automatic. No scripting or other input needed.) 
#
# Or by using wifi via iwctl. Example: 
#
# iwctl device list
# iwctl station <stationname> scan
# iwctl station <stationname> get-networks
# iwctl station <stationname> connect <ssid> -P <password>
#
# ***USAGE*** 
# curl -LO https://raw.githubusercontent.com/simpyll/dalis/main/dalis-barebones.sh
# sh dalis-barebones.sh

# wipe file system and create two new partitions (boot and root).
sgdisk -Z -a 2048 -o /dev/sda -n 1::+512M -n 2::: -t 1:ef00 

# enable NTP
timedatectl set-ntp true

# set timezone
timedatectl set-timezone America/Chicago

# make sda1 a fat32 partition for boot
mkfs.fat -F32 /dev/sda1

# make a boot directory at /mnt/boot
mkdir -p /mnt/boot 

# mount sda1 to boot directory
mount /dev/sda1 /mnt/boot 

# make a ext4 file system for root on sda2
mkfs.ext4 /dev/sda2

# mount /dev/sda2 to /mnt
mount /dev/sda2 /mnt

# install base packages to mnt
pacstrap /mnt base base-devel linux linux-firmware intel-ucode vim

# generate a partition table 
genfstab -U /mnt > /mnt/etc/fstab

# set keymap inside chroot 
arch-chroot /mnt /bin/bash -c 'echo "KEYMAP=us" > /etc/vconsole.conf'

# set language inside chroot 
arch-chroot /mnt /bin/bash -c 'echo "en_US.UTF-8 UTF-8" > /etc/locale.gen'

# set timezone inside chroot 
arch-chroot /mnt /bin/bash -c 'ln -s /usr/share/zoneinfo/America/Chicago /etc/localtime'

# set generate localisation from templates inside chroot 
arch-chroot /mnt /bin/bash -c 'locale-gen'

# set clock inside chroot 
arch-chroot /mnt /bin/bash -c 'hwclock --systohc --utc'

# Set the hosts file inside chroot
arch-chroot /mnt /bin/bash -c 'echo "127.0.0.1 localhost
::1 localhost
127.0.1.1 arch.localdomain arch" >> /etc/hosts'

# set hostname inside chroot
arch-chroot /mnt /bin/bash -c 'echo "arch" > /etc/hostname'

# set root password inside chroot
arch-chroot /mnt /bin/bash -c 'passwd'

# generate the ramdisks using the presets inside chroot
arch-chroot /mnt /bin/bash -c 'mkinitcpio -P'

arch-chroot /mnt /bin/bash -c 'useradd -m david'
arch-chroot /mnt /bin/bash -c 'passwd david'
arch-chroot /mnt /bin/bash -c 'usermod -aG wheel,audio,video,storage david'

# uncomment wheel in visudo
# vim visudo

arch-chroot /mnt /bin/bash -c 'pacman -S --noconfirm xorg-server xorg-apps xorg-xinit xdg-user-dirs xorg'
arch-chroot /mnt /bin/bash -c 'pacman -S --noconfirm i3 i3-gaps i3blocks i3lock numlockx'

arch-chroot /mnt /bin/bash -c 'pacman -S --noconfirm networkmanager network-manager-applet dhcpcd iw wpa_supplicant dialog openssh'
arch-chroot /mnt /bin/bash -c 'systemctl enable sshd'
arch-chroot /mnt /bin/bash -c 'systemctl enable dhcpcd'
arch-chroot /mnt /bin/bash -c 'systemctl enable NetworkManager.service'

# Improve laptop battery consumption
arch-chroot /mnt /bin/bash -c 'pacman -S --noconfirm tlp tlp-rdw powertop acpi'
arch-chroot /mnt /bin/bash -c 'systemctl enable tlp'
# arch-chroot /mnt /bin/bash -c 'systemctl enable tlp-sleep'
arch-chroot /mnt /bin/bash -c 'systemctl mask systemd-rfkill.service'
arch-chroot /mnt /bin/bash -c 'systemctl mask systemd-rfkill.socket'

# bootloader
arch-chroot /mnt /bin/bash -c 'pacman -S --noconfirm grub efibootmgr sudo' 
# arch-chroot /mnt /bin/bash -c 'mkfs.fat -F32 /dev/sda1'
# arch-chroot /mnt /bin/bash -c 'mkdir /boot/EFI'
# arch-chroot /mnt /bin/bash -c 'mount /dev/sda1 /boot/EFI' 
# arch-chroot /mnt /bin/bash -c 'bootctl install --esp-path /boot/EFI'
# arch-chroot /mnt /bin/bash -c 'grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/EFI'
# arch-chroot /mnt /bin/bash -c 'grub-mkconfig -o /boot/grub/grub.cfg'

# Now we just unmount the filesystem
# umount -l /mnt

# all you need to do now is `poweroff` or `restart`. I prefer to poweroff so I can remove the usb without concern before booting back on.
