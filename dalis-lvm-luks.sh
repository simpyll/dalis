
### Arch Linux Installation Notes
###    UEFI GPT LVM on LUKS (single drive)
###
### These are my personal notes to install Arch.  Its not a script, but step by step instructions.  If using
### please be aware that every step should be considered before applying, to personalize your 
### installations appropriately.
###
 
# boot to arch linux boot prompt

# installation

# setup networking
ping -c 3 www.google.ca
# eth connections just work or me, so…
wifi-menu  # select and log in
ping -c 3 www.google.ca

# now to set up LVM on LUKS (only if you are using a single physical disk, see below for LUKS on LVM)
modprobe dm-mod

# partition the disk
lsblk
gdisk /dev/sda
# I created 2 partitions on the single drive (/boot is now your EFI partition)
#     /dev/sda1 500MB fat32 EFI 
#     /dev/sda2 remaining as Linux LVM
# set up single disk encryption (LVM on LUKs)
cryptsetup —verify-passphrase luksFormat /dev/sda2
cryptsetup open —type luks /dev/sda2 lvm
# now set up LVM (on a single disk)
pvcreate /dev/mapper/lvm
vgcreate system /dev/mapper/lvm
lvcreate -L 16G -n swap system
lvcreate -l 100%FREE -n root system
# format the new filesystems
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/mapper/system-root
mkswap /dev/mapper/system-swap
swapon /dev/mapper/system-swap
# mount the new filesystems
mount /dev/mapper/system-root /mnt
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot
lsblk -f /dev/sda

# now pacstrap the system
#     select a close mirror and move to the top of the file, save and close
vim /etc/pacman.d/mirrorlist
pacstrap -i /mnt base base-devel
# generate fstab
genfstab -U -p  /mnt/ >> /mnt/etc/fstab
#     confirm content
vim /mnt/etc/fstab

# chroot to the new filesystem
arch-chroot /mnt /bin/bash
export PS1="(CHROOT) $PS1"

# setup locales
#     uncomment your locale and save
vi /etc/locale.gen
locale-gen
echo LANG=en_CA.UTF-8 > /etc/locale.conf
export LANG=en_CA.UTF-8

# set the tz and clock
ln -fs /usr/share/zoneinfo/Canada/Pacific /etc/localtime
hwclock —systohc —utc

# hostname
echo arod > /etc/hostname
#       add ‘arod’ to the beginning of both localhost row aliases
vi /etc/hosts

# setup networking for next boot
pacman -S networkmanager 
systemctl enable NetworkManager.service
# disable network services not needed
systemctl disable netctl.service

# create ramdisk
#    on the HOOKS=“” line, add ‘encrypt lvm2’ between ‘block’ and ‘filesystems’
#    on the MODULES=“” line, add ‘dm-mod’
vi /etc/mkinitcpio.conf
mkinitcpio -p linux

# set root password
passwd

# make sure vim is installed
pacman -S vim

# set up the boot loader, goodbye grub, hello systemd
bootctl install
# set up the loader content with:
#       timeout 3
#       default arch
vim /boot/loader/loader.conf
# now set up the arch.conf with:
#       title       Arch Linux (encrypted)
#       linux      /vmlinuz-linux
#       initrd     /initramfs-linux.img
#       options  cryptdevice=/dev/sda2:system root=/dev/mapper/system-root quiet rw
vim /boot/loader/entries.arch.conf

# exit and unmount and reboot
exit
umount -R /mnt
reboot
#     remove your USB or CD
#     fingers crossed
