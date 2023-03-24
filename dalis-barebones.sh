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
mkdir /mnt/boot 

# mount sda1 to boot directory
mount /dev/sda1 /mnt/boot 

# make a ext4 file system for root on sda2
mkfs.ext4 /dev/sda2

# mount /dev/sda2 to /mnt
mount /dev/sda2 /mnt

# install base packages to mnt
pacstrap /mnt base base-devel linux linux-firmware intel-ucode

# generate a partition table 
genfstab -U /mnt > /mnt/etc/fstab

# set locale inside chroot 
arch-chroot /mnt /bin/bash -c 'echo "en_US.UTF-8" > /etc/locale.gen'

# set keymap inside chroot 
arch-chroot /mnt /bin/bash -c 'echo "KEYMAP=us" > /etc/vconsole.conf'

# set language inside chroot 
arch-chroot /mnt /bin/bash -c 'echo "LANG=en_US.UTF-8" > /etc/locale.conf'

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

# set root password inside chroot
arch-chroot /mnt /bin/bash -c 'passwd'

# generate the ramdisks using the presets inside chroot
arch-chroot /mnt /bin/bash -c 'mkinitcpio -P'

# bootloader: systemd-boot to /boot/
arch-chroot /mnt /bin/bash -c 'bootctl install'

/boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=UUID=$(blkid -s UUID -o value /dev/sda2) rw
