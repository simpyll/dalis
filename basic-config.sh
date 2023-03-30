echo "KEYMAP=us" > /etc/vconsole.conf
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
ln -s /usr/share/zoneinfo/America/Chicago /etc/localtime
arch-chroot /mnt /bin/bash -c 'locale-gen
arch-chroot /mnt /bin/bash -c 'hwclock --systohc --utc

echo "127.0.0.1 localhost
::1 localhost
127.0.1.1 archlinux.localdomain archlinux" >> /etc/hosts

echo "archlinux" > /etc/hostname
hostnamectl set-hostname archlinux

useradd -m david
passwd david
usermod -aG wheel,audio,video,storage david
arch-chroot /mnt /bin/bash -c perl -i -pe 's/# (%wheel ALL=\(ALL\) ALL)/$1/' /etc/sudoers
