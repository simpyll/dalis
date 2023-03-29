#!/bin/bash

sgdisk -Z -a 2048 -o /dev/sda -n 1::+512M -n 2::: -t 1:ef00 

timedatectl set-ntp true
timedatectl set-timezone America/Chicago

mkfs.fat -F32 /dev/sda1
yes | mkfs.ext4 /dev/sda2

mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

pacstrap /mnt base base-devel linux linux-headers intel-ucode vim

genfstab -p /mnt >> /mnt/etc/fstab

mkinitcpio -p Linux 

arch-chroot /mnt /bin/bash -c 'pacman -S --noconfirm netctl dialog dhcpcd iw wpa_supplicant networkmanager network-manager-applet'
arch-chroot /mnt /bin/bash -c 'pacman -S --noconfirm grub efibootmgr' 

arch-chroot /mnt /bin/bash -c 'grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch_grub --recheck'
arch-chroot /mnt /bin/bash -c 'grub-mkconfig -o /boot/grub/grub.cfg'
arch-chroot /mnt /bin/bash -c 'efibootmgr -d /dev/sda -c -L "Arch Linux" -l vmlinuz-linux -u "root=UUID=$(blkid -s UUID -o value /dev/sda2) rw quiet initrd=intel-ucode.img initrd=initramfs-linux.img"'

arch-chroot /mnt /bin/bash -c 'systemctl enable dhcpcd' 
arch-chroot /mnt /bin/bash -c 'systemctl start dhcpcd'
arch-chroot /mnt /bin/bash -c 'systemctl enable NetworkManager.service' 
arch-chroot /mnt /bin/bash -c 'systemctl start NetworkManager.service' 

arch-chroot /mnt /bin/bash -c 'passwd'

arch-chroot /mnt /bin/bash -c 'echo "KEYMAP=us" > /etc/vconsole.conf'
arch-chroot /mnt /bin/bash -c 'echo "en_US.UTF-8 UTF-8" > /etc/locale.gen'
arch-chroot /mnt /bin/bash -c 'ln -s /usr/share/zoneinfo/America/Chicago /etc/localtime'
arch-chroot /mnt /bin/bash -c 'locale-gen'
arch-chroot /mnt /bin/bash -c 'hwclock --systohc --utc'
arch-chroot /mnt /bin/bash -c 'echo "127.0.0.1 localhost
::1 localhost
127.0.1.1 arch.localdomain arch" >> /etc/hosts'
arch-chroot /mnt /bin/bash -c 'echo "archlinux" > /etc/hostname'
arch-chroot /mnt /bin/bash -c 'hostnamectl set-hostname archlinux'

arch-chroot /mnt /bin/bash -c 'useradd -m david'
arch-chroot /mnt /bin/bash -c 'passwd david'
arch-chroot /mnt /bin/bash -c 'usermod -aG wheel,audio,video,storage david'
arch-chroot /mnt /bin/bash -c 'perl -i -pe 's/# (%wheel ALL=\(ALL\) ALL)/$1/' /etc/sudoers'

umount -R /mnt 
poweroff
