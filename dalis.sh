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

arch-chroot /mnt /bin/bash -c 'pacman -S --noconfirm dhcpcd networkmanager'
arch-chroot /mnt /bin/bash -c 'pacman -S --noconfirm grub efibootmgr' 

arch-chroot /mnt /bin/bash -c 'grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch_grub --recheck'
arch-chroot /mnt /bin/bash -c 'grub-mkconfig -o /boot/grub/grub.cfg'
arch-chroot /mnt /bin/bash -c 'efibootmgr -d /dev/sda -c -L "Arch Linux" -l vmlinuz-linux -u "root=UUID=$(blkid -s UUID -o value /dev/sda2) rw quiet initrd=intel-ucode.img initrd=initramfs-linux.img"'

arch-chroot /mnt /bin/bash -c 'systemctl enable dhcpcd' 
arch-chroot /mnt /bin/bash -c 'systemctl start dhcpcd'
arch-chroot /mnt /bin/bash -c 'systemctl enable NetworkManager.service' 
arch-chroot /mnt /bin/bash -c 'systemctl start NetworkManager.service' 

arch-chroot /mnt /bin/bash -c 'passwd'

umount -R /mnt 
poweroff
