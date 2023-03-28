mkinitcpio -p linux

pacman -S grub-efi-x86_64 efibootmgr

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch
grub-mkconfig -o /boot/grub/grub.cfg
