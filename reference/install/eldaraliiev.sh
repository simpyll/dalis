#!/bin/bash

# Создание разделов
cgdisk /dev/sda

# Форматирование разделов
mkfs.fat -F32 /dev/sda1
mkswap /dev/sda2 -L swap
mkfs.ext4 /dev/sda3 -L root
mkfs.ext4 /dev/sda4 -L home

# Монтирование разделов
mount /dev/sda3 /mnt
mkdir /mnt/{boot,home}
mount /dev/sda1 /mnt/boot
mount /dev/sda4 /mnt/home
swapon /dev/sda2

# Добавление зеркала в Pacman
nano /etc/pacman.d/mirrorlist
# Server = https://archlinux.ip-connect.vn.ua/$repo/os/$arch

# Установка базовой системы
pacstrap -i /mnt base base-devel
pacstrap -i /mnt netctl dialog iw wpa_supplicant intel-ucode

# Генерация fstab
genfstab -p /mnt >> /mnt/etc/fstab

# Вход в новую систему
arch-chroot /mnt /bin/bash

# Создание загрузочного RAM диска
nano /etc/mkinitcpio.conf # HOOKS < keymap, MODULES < i915
mkinitcpio -p linux

# Установка GRUB
pacman -S grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch_grub --recheck
grub-mkconfig -o /boot/grub/grub.cfg
# или сразу в UEFI
efibootmgr -d /dev/sda -c -L "Arch Linux" -l vmlinuz-linux -u "root=UUID=$(blkid -s UUID -o value /dev/sda3) rw quiet resume=UUID=$(blkid -s UUID -o value /dev/sda2) initrd=intel-ucode.img initrd=initramfs-linux.img"

# Установка пароля для root, выход из системы, размонтирование разделов и перезагрузка
passwd
exit
umount /mnt/{boot,home,}
reboot

# Вход в систему и настройка
hostnamectl set-hostname archlinux
timedatectl set-timezone Europe/Kiev

# Руссификация системы
nano /etc/locale.gen #ru_RU.UTF-8 UTF-8
locale-gen
localectl set-keymap ru
setfont cyr-sun16
localectl set-locale LANG="ru_RU.UTF-8"
export LANG=ru_RU.UTF-8
echo "FONT=cyr-sun16" >> /etc/vconsole.conf
mkinitcpio -p linux
grub-mkconfig -o /boot/grub/grub.cfg

# Настройка Pacman
nano /etc/pacman.conf
#[multilib]
#Include = /etc/pacman.d/mirrorlist
#[archlinuxfr]
#SigLevel = Never
#Server = http://repo.archlinux.fr/$arch

# Создание пользователя и установка пароля
useradd -m -g users -G audio,games,lp,optical,power,scanner,storage,video,wheel -s /bin/bash zim
passwd zim

# Настройка сети
systemctl enable dhcpcd
systemctl start dhcpcd

# Обновление системы
pacman -Syu

# Установка и настройка sudo
pacman -S sudo
nano /etc/sudoers # %wheel ALL=(ALL) ALL
exit

# Установка основных пакетов
sudo pacman -S xorg-server xorg-xinit xorg-server-utils mesa-libgl lib32-mesa-libgl xterm xf86-input-libinput xf86-video-intel yaourt

# Установка Gnome
sudo pacman -S gnome gnome-tweak-tool gedit networkmanager gdm
sudo systemctl enable gdm
sudo reboot
