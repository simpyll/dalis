#!/bin/bash

sgdisk -Z -a 2048 -o /dev/sda -n 1::+512M -n 2::: -t 1:ef00 

mkfs.fat -F32 /dev/sda1
yes | mkfs.ext4 /dev/sda2

mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

pacstrap /mnt base base-devel linux linux-headers intel-ucode vim

genfstab -p /mnt >> /mnt/etc/fstab

arch-chroot /mnt /bin/bash

mkinitcpio -p Linux 

arch-chroot /mnt /bin/bash -c 'pacman -S --noconfirm netctl dialog dhcpcd iw wpa_supplicant networkmanager network-manager-applet'
arch-chroot /mnt /bin/bash -c 'pacman -S --noconfirm grub efibootmgr' 

arch-chroot /mnt /bin/bash -c 'grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch_grub --recheck'
arch-chroot /mnt /bin/bash -c 'grub-mkconfig -o /boot/grub/grub.cfg'
arch-chroot /mnt /bin/bash -c 'efibootmgr -d /dev/sda -c -L "Arch Linux" -l vmlinuz-linux -u "root=UUID=$(blkid -s UUID -o value /dev/sda2) rw quiet initrd=intel-ucode.img initrd=initramfs-linux.img"'

arch-chroot /mnt /bin/bash -c 'systemctl enable dhcpcd'
arch-chroot /mnt /bin/bash -c 'systemctl enable NetworkManager.service'
