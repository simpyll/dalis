#!/bin/bash

cgdisk /dev/sda

mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2 -L root

mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

pacstrap -i /mnt base base-devel Linux linux-headers
pacstrap -i /mnt netctl dialog iw wpa_supplicant intel-ucode

genfstab -p /mnt >> /mnt/etc/fstab

arch-chroot /mnt /bin/bash

mkinitcpio -p linux

pacman -S grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch_grub --recheck
grub-mkconfig -o /boot/grub/grub.cfg
efibootmgr -d /dev/sda -c -L "Arch Linux" -l vmlinuz-linux -u "root=UUID=$(blkid -s UUID -o value /dev/sda2) rw quiet initrd=intel-ucode.img initrd=initramfs-linux.img"
