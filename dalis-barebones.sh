#!/bin/bash

sgdisk -Z -a 2048 -o /dev/sda -n 1::+512M -n 2::: -t 1:ef00 

mkfs.fat -F32 /dev/sda1 -L boot
mkfs.ext4 /dev/sda2 -L root

mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

pacstrap -i /mnt base base-devel linux linux-headers intel-ucode vim

genfstab -p /mnt >> /mnt/etc/fstab

arch-chroot /mnt /bin/bash

mkinitcpio -p Linux 

arch-chroot /mnt /bin/bash -c 'pacman -S netctl dialog dhcpcd iw wpa_supplicant'
arch-chroot /mnt /bin/bash -c 'pacman -S grub efibootmgr'
arch-chroot /mnt /bin/bash -c 'grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch_grub --recheck'
arch-chroot /mnt /bin/bash -c 'grub-mkconfig -o /boot/grub/grub.cfg'
arch-chroot /mnt /bin/bash -c 'efibootmgr -d /dev/sda -c -L "Arch Linux" -l vmlinuz-linux -u "root=UUID=$(blkid -s UUID -o value /dev/sda2) rw quiet initrd=intel-ucode.img initrd=initramfs-linux.img"'
