# Secure Arch Linux Installation
 By Braxton ([taxborn](https://taxborn.com)) Fair - _updated 11.11.2020_

## Table of Contents
1. Setup
	- USB
	- Wiping
	- Booting
2. Installation
	- Partitioning
	- Creating volumes
	- Mount volumes
	- Update mirrors
	- Base installation with pacstrap
	- Update locales
	- Create users
	- Create boot loader
	- Encrypt /home directory
3. Graphics Drivers
	- Installation
	- Pacman hook
	- Dual monitor configuration
4. Programs
5. Hardening

# Setup

### USB
We first need to download Arch Linux, which can be done through a magnet link, or direct download. It is good practice after download to [verify the signature](https://wiki.archlinux.org/index.php/Installation_guide#Verify_signature).

To install Arch Linux, we need to create a [installation medium](https://wiki.archlinux.org/index.php/USB_flash_installation_medium) with a USB drive. On Windows, we can use [Rufus](https://rufus.ie). On Linux, we can use either `dd` or `etchercli`, I am going to use `dd` with the following command:

```bash
dd bs=4M if=path/to/archlinux.iso of=/dev/sdX status=progress oflag=sync
```

### Wiping
First off to building a secure installation is securely wiping the disk of any and all previous data. Some free approaches can be found here: [https://wiki.archlinux.org/index.php/Securely_wipe_disk](https://wiki.archlinux.org/index.php/Securely_wipe_disk).

The method I will be using on my SSD is called `hdparm`, with the following command:

```bash
hdparm -I /dev/sda
hdparm --user-master u --security-set-pass p /dev/sda
hdparm --user-master u --security-erase-enhanced p /dev/sda # Wait roughly 10 minutes
```

The method I will be using on my NVMe SSD is called `nvme`, with the following command:

```bash
nvme format /dev/nvme0 -n 1 -ses 1
```

### Booting
As soon as you are booted into the USB, we are going to check a few things to make sure we are all set up!

```bash
ls /sys/firmware/efi/efivars
```
This is to verify that UEFI mode is enabled, as long as it returns a bunch of files with _seemingly_ randomized names, you're all set.

Next, we are going to set our timezone and hardware clock with the following commands:
```bash
timedatectl set-ntp true && timedatectl status
```
```bash
hwclock --systohc
```

# Installation

### Partitioning

For this, I'm using fdisk.

```bash
fdisk /dev/nvme0n1

# Now you have to go through a couple of steps to prepare
# partitions:
#   - Press 'g' and Enter keys to create a new GPT disk label
#   - Press 'n' and Enter keys to create a new partition
#   - "Partition number (1-128, default 1):" -- just hit Enter
#   - "First sector ..." -- just hit Enter
#   - "Last sector ..." -- this one determines a size of /boot
#     partition to use. My personal go-to size is +10G (10GB of
#     space) but you may want to choose a smaller amount. Around
#     +2GB should be enough. Say, amount of GBs you want is X.
#     Then type in "+XGB" and press Enter.
#   - If you received a prompt mentioning "remove a signature"
#     just Type 'Y' and Enter. If at some point you'll receive
#     a warning that kernel still uses an old partition table
#     the reader'd have to go through 'fdisk /dev/<>' for each
#     disk creating new disk labels with empty partitions,
#     reboot and start from the very beginning of this guide
#     (don't forget to 'w' + Enter in the very end for each
#     disk to write new partition table.
#   - Press 't' and Enter
#   - Press '1' and Enter (this will set a partition type to
#     'EFI System' and this one is a damn important thing to
#     get right)
#   - Now we have to create a second partition for a part of
#     the disk that will be handled by LVM. Press 'n' and Enter.
#   - "Partition number ..." -- just hit Enter
#   - "First sector ..." -- just hit Enter
#   - "Last sector ..." -- just hit Enter
#   - Press 't' and Enter
#   - Press '2' and Enter 
#   - Type in '30' and Enter (was '31' in 2018)
#   - The reader should see "Changed type of partition 'Linux
#     filesystem' to 'Linux LVM'"
#   - Press 'p' and Enter. Verify that partition table looks
#     about right. If not start from the very beginning (from
#     "Press 'g' and Enter" step.
#   - Press 'w' and Enter

# Now we have to format a future /boot partition
mkfs.fat -F32 /dev/sda1

# Right, next is setting up LVM group
pvcreate /dev/sda2

# You can use any name instead of 'archvol0' here
vgcreate archvol0 /dev/sda2

fdisk /dev/sda

# Steps inside fdisk:
#   - Press 'g' and Enter
#   - Press 'n' and Enter
#   - "Partition number ..." -- just hit Enter
#   - "First sector ..." -- just hit Enter
#   - "Last sector ..." -- just hit Enter
#   - Press 't' and Enter
#   - Type in '30' and Enter (was '31' in 2018)
#   - Press 'w' and Enter

# Now we can add a second disk to the volume group we
# created previously:
pvcreate /dev/sda1
vgextend archvol0 /dev/sda1

# Verify that a total size of the volume group is
# correct (check a 'VG Size' field):
vgdisplay
```

### Creating volumes

```bash

lvcreate -L 512G -n cryptroot archvol0
lvcreate -L 32G -n cryptswap archvol0
lvcreate -L 16G -n crypttmp archvol0
lvcreate -l 100%FREE -n crypthome archvol0

cryptsetup luksFormat --type luks2 /dev/archvol0/cryptroot
cryptsetup open /dev/archvol0/cryptroot root

mkfs.ext4 /dev/mapper/root
mount /dev/mapper/root /mnt

mkswap /dev/archvol0/cryptswap
swapon /dev/archvol0/cryptswap
```

### Mount volumes

```bash
mkdir /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot

mkdir /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi
```

### Update mirrors

```bash
reflector --country 'United States' --country 'Canada' --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
```

### Base installation with pacstrap

```bash
pacstrap /mnt base base-devel linux linux-firmware lvm2 mkinitcpio reflector vim git amd-ucode networkmanager dhcpcd

arch-chroot /mnt
```

### Update locales

```bash
ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime
hwclock --systohc

vim /etc/locale.gen # en_US.UTF-8
locale-gen

locale > /etc/locale.conf
```

### Create users

```bash
echo "pythagoras" > /etc/hostname

# ^127.0.0.1 localhost
# ^::1       localhost
# ^127.0.1.1 HOSTNAME.localdomain HOSTNAME
vim /etc/hosts

passwd # root password
useradd -mg users -G wheel,storage,power taxborn -s /bin/bash
passwd taxborn

visudo
```

### Create boot loader

```bash
systemctl enable fstrim.timer
systemctl enable dhcpcd@enp2s0
systemctl enable NetworkManager

# ^HOOKS=(base udev autodetect keyboard keymap consolefont modconf block lvm2 encrypt filesystems fsck)
vim /etc/mkinitcpio.conf

mkinitcpio -p linux

# ^swap /dev/archvol0/cryptswap /dev/urandom swap,cipher=aes-xts-plain64,size=256
# ^tmp  /dev/archvol0/crypttmp  /dev/urandom tmp,cipher=aes-xts-plain64,size=256
# ^home /dev/archvol0/crypthome /etc/luks-keys/home
vim /etc/crypttab

# ^/dev/mapper/root /     ext4  defaults 0 1
# ^/dev/sda1        /boot vfat  defaults 0 2
# ^/dev/mapper/home /home ext4  defaults 0 2
# ^/dev/mapper/tmp  /tmp  tmpfs defaults 0 0
# ^/dev/mapper/swap none  swap  sw       0 0
vim /etc/fstab
```

### Encrypt /home directory

```bash
cryptsetup luksFormat --type luks2 -v /dev/archvol0/crypthome /etc/luks-keys/home
cryptsetup -d /etc/luks-keys/home open /dev/archvol0/crypthome home

mkfs.ext4 /dev/mapper/home
```

# Graphics Drivers

### Installation

```bash
# Install necessary packages
sudo pacman -S linux-headers nvidia-dkms libglvnd nvidia-utils opencl-nvidia lib32-libglvnd lib32-nvidia-utils lib32-opencl-nvidia mesa nvidia-settings

# Add the nVidia hooks
# MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
sudo vim /etc/mkinitcpio.conf

# Update the bootloader
# Append "nvidia-drm.modeset=1" to the options line
sudo vim /boot/loader/entries/arch.conf
```

### Pacman hook

```bash
sudo vim /etc/pacman.d/hooks/nvidia.hook

#[Trigger]
#Operation=Install
#Operation=Upgrade
#Operation=Remove
#Type=Package
#Target=nvidia

#[Action]
#Depends=mkinitcpio
#When=PostTransaction
#Exec=/usr/bin/mkinitcpio -P
```

### Dual monitor configuration

```bash
# https://gist.github.com/taxborn/1675226552053053a53a91fb99e6bca9

sudo vim /etc/X11/xorg.conf
```

# Programs

```bash
sudo pacman -S firefox dmenu rxvt-unicode pulseaudio pavucontrol arandr
```
# Hardening
