#! /bin/bash

sgdisk -Z -a 2048 -o /dev/sda -n 1::+512M -n 2::: -t 1:ef00
cryptsetup -c aes-xts-plain64 -s 512 -h sha512 -i 5000 --use-random --verify-passphrase luksFormat /dev/sda2
cryptsetup luksOpen /dev/sda2 luks
pvcreate /dev/mapper/luks
vgcreate vg /dev/mapper/luks
lvcreate -l 100%FREE vg
mkfs.ext4 /dev/mapper/vg-lvol0
mkfs.fat -F32 /dev/sda1
mount /dev/mapper/vg-lvol0 /mnt
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot

pacstrap /mnt \
    base base-devel linux linux-firmware \
    iw wget openssh wpa_supplicant wireless_tools dhcpcd dialog git \
    intel-ucode nvidia nvidia-libgl nidia-utils \
#   xorg-server xorg-server-utils xorg-xinit xf86-input-synaptics xf86-video-intel \
#   i3 rxvt-unicode \
#   vim vim-spell-en \
#   cups cups-filters foomatic-db foomatic-db-engine foomatic-db-nonfree foomatic-filters ghostscript gsfonts gutenprint \
#   aide clamav lynis \
#   pm-utils acpi acpid cpupower \
#   aspell aspell-en hunspell hunspell-en \


genfstab -pU /mnt >> /mnt/etc/fstab
echo 'tmpfs	/tmp	tmpfs	defaults,noatime,mode=1777	0	0' >> /mnt/etc/fstab
  
arch-chroot /mnt /bin/bash -c '
echo "en_US.UTF-8" > /etc/locale.gen
echo "KEYMAP=us" > /etc/vconsole.conf
echo "LANG=en_US.UTF-8" > /etc/locale.conf
ln -s /usr/share/zoneinfo/America/Chicago /etc/localtime
locale-gen
hwclock --systohc --utc
'

arch-chroot /mnt /bin/bash -c '
echo arch > /etc/hostname
'

arch-chroot /mnt /bin/bash -c '
sed -i "/^HOOK/s/block/block keymap encrypt/" /etc/mkinitcpio.conf
sed -i "/^HOOK/s/filesystems/lvm2 filesystems/" /etc/mkinitcpio.conf
sed -i "/^MODULES/s/''/'ext4'/" /etc/mkinitcpio.conf
mkinitcpio -p linux
bootctl --path=/boot install
'

arch-chroot /mnt /bin/bash -c '
sed -i "/127.0.0.1/s/$/ arch/" /etc/hosts
sed -i "/::1/s/$/ arch/" /etc/hosts
'
arch-chroot /mnt /bin/bash -c '
cat << EOF > /boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd /intel-ucode.img
initrd /initramfs-linux.img
options cryptdevice=UUID=$(blkid -s UUID -o value /dev/sda2):lvm:allow-discards root=/dev/mapper/vg0-root rw quiet loglevel=0 udev.log-priority=3
EOF

cat << EOF > /boot/loader/loader.conf
default Arch Linux
timeout 0
editor 0
EOF
'
arch-chroot /mnt /bin/bash -c 'passwd'
