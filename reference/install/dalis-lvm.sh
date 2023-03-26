# install arch linux with lvm and efi boot

# set keymap
loadkeys en_US

# create partitions
cfdisk /dev/sda
# 512M type efi partition
# 19.5G type lvm partition

# format efi partition
mkfs.vfat -F32 /dev/sda1

# create lvm volume
pvcreate /dev/sda2

# create volume group
vgcreate lvm /dev/sda2

# create logical volumes
lvcreate -L 2G lvm -n swap
lvcreate -l 100%FREE lvm -n root

# format lvm volume
mkfs.ext4 /dev/lvm/root

# create swap and activate
mkswap /dev/lvm/swap
swapon /dev/lvm/swap

# mount the volumes
mount /dev/lvm/root /mnt

# create boot and mount volume
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

# install base system and devel
pacstrap -i /mnt base base-devel
# for lts install
pacstrap -i /mnt $(pacman -Sqg base | sed 's/^linux$/&-lts/')

# create fstab
genfstab -U -p /mnt >> /mnt/etc/fstab

# change root
arch-chroot /mnt /bin/bash

# define hostname
echo calypso.local > /etc/hostname

# uncomment locale information
nano /etc/locale.gen

# generate locale 
locale-gen

# set keymap on boot
echo "KEYMAP=pt-latin9" > /etc/vconsole.conf

# time and date
ln -s /usr/share/zoneinfo/Europe/Lisbon /etc/localtime
hwclock --systohc --utc

# install bootloader
bootctl install

# change bootloader entries
nano /boot/loader/loader.conf

# loader.conf
default arch
timeout 3
editor  0

# get UUID
blkid /dev/mapper/lvm-root

# create bootloader entrie
nano /boot/loader/entries/arch.conf

# arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=UUID=<UUID> rw
# arch.conf lts
title   Arch Linux
linux   /vmlinuz-linux-lts
initrd  /initramfs-linux-lts.img
options root=UUID=<UUID> rw

# configure mkinitcpio with lvm hook
nano /etc/mkinitcpio.conf

# ESXi kernel modules
MODULES="vmw_balloon vmw_pvscsi vmw_vmci vmxnet3 vsock vmw_vsock_vmci_transport"

# add 'lvm2' to HOOKS before filesystems
HOOKS=... lvm2 filesystems ...

# generate initrd
mkinitcpio -p linux
# initrd for lts
mkinitcpio -p linux-lts

# set root password
passwd

# create user with sudo priviledges
useradd -m -g users -G wheel -s /bin/bash kz0

# edit visudo
EDITOR=nano visudo

# uncomment 
%wheel ALL=(ALL) ALL

# add multilib repo for 32 bits
nano /etc/pacman.conf

# pacman.conf
[multilib]
Include = /etc/pacman.d/mirrorlist

# add yaourt
[archlinuxfr]
SigLevel = Never
Server = http://repo.archlinux.fr/$arch

# install systemd-swap, ssh and yaourt
pacman -Syu systemd-swap openssh yaourt

# enable swap,network and ssh services
systemctl enable systemd-swap.service
systemctl enable dhcpcd.service
systemctl enable sshd.socket

# exit chroot, umount and reboot
exit
umount -R /mnt
reboot
