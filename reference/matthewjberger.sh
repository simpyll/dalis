# !/bin/bash

# UEFI/GPT Installation
# This is meant to be run from the archiso live media command line

host_name=$1
root_password=$2
user_name=$3
user_password=$4

# Check for UEFI
echo "Checking for UEFI..."
efivar -l >/dev/null 2>&1
if [[ $? -ne 0 ]]; then 
    echo "ERROR: UEFI not detected, exiting..."
    exit 0
fi
echo "UEFI detected!"

# Reset the screen
reset

# Update the system clock
timedatectl set-ntp true

# Zap disk
echo "Zapping disk..."
sgdisk --zap-all /dev/sda

# Set 1 ESP partition and 1 primary ext4 partition
parted /dev/sda -s mklabel gpt
echo "Creating /dev/sda1..."
parted /dev/sda -s mkpart ESP fat32 1MiB 551MiB
parted /dev/sda -s set 1 esp on
echo "Creating /dev/sda2..."
parted /dev/sda -s mkpart primary ext4 551MiB 100%

# Format the ESP partition as fat32
echo "Formatting the ESP partition as fat32..."
yes | mkfs.fat -F32 /dev/sda1

# Format the primary partition as ext4
echo "Formatting the primary partition as ext4..."
yes | mkfs.ext4 /dev/sda2

# Mount the partitions
echo "Mounting partitions..."
mount /dev/sda2 /mnt
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot

# Get available mirrors for the US, and then use rankmirrors to sort them
echo "Updating mirrorlist..."
curl -s "https://www.archlinux.org/mirrorlist/?country=US&protocol=https&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 5 - > /etc/pacman.d/mirrorlist

# Install the base packages
echo "Installing base packages..."
yes '' | pacstrap -i /mnt base base-devel

# Generate the fstab file
echo "Generating fstab..."
genfstab -U /mnt > /mnt/etc/fstab

# Chroot into the system
arch-chroot /mnt /bin/bash <<EOF
# Set the time zone
echo "Setting time zone..."
ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime

# Setup the hardware clock
echo "Setting up the hardware clock..."
hwclock --systohc

# Setup locale
echo "Setting locale..."
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
export LANG=en_US.UTF-8 
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

# Create the hostname file
echo "Setting hostname..."
echo $host_name > /etc/hostname

echo "Setting up hosts file..."
cat << CONF > /etc/hosts
127.0.0.1 localhost
::1 localhost
127.0.1.1 $host_name.localdomain arch
CONF

# Create a new initramfs
echo "Generating initramfs"
mkinitcpio -p linux

# Setup networking
echo "Installing wifi packages"
pacman --noconfirm -S iw wpa_supplicant dialog wpa_actiond
systemctl enable dhcpcd.service

# Setup a password for the root account
echo "Setting root password"
echo "root:${root_password}" | chpasswd

# Install a bootloader
echo "Installing systemd-boot bootloader..."
bootctl install

# Configure bootloader
echo "Setting up loader configuration..."
cat << CONF > /boot/loader/loader.conf
default arch
timeout 4
editor no
CONF

echo "Setting up Arch LTS bootloader entry..."
cat << CONF > /boot/loader/entries/arch.conf
title          Arch Linux LTS
linux          /vmlinuz-linux-lts
initrd         /initramfs-linux-lts.img
options        root=$(blkid | grep sda2 | cut -f 4 -d ' ' | tr -d '"') rw
CONF

# Install linux lts kernel
echo "Installing Linux LTS Kernel"
pacman --noconfirm -S linux-lts linux-lts-headers

# Add a non-root user
useradd -m -g users -s /bin/bash $user_name
echo "${user_name}:${user_password}" | chpasswd

# Make the non-root user a sudoer
echo odin ALL=\(ALL\) NOPASSWD: ALL >> /etc/sudoers

# Do a full system upgrade
pacman --noconfirm -Syu

# Install an aur helper
pacman --noconfirm -S git pkgfile
cd /home/$user_name
git clone https://aur.archlinux.org/yay.git
chown $user_name yay
cd yay
su $user_name -c "yes | makepkg -sri"

# Install tools
su $user_name -c "yes | yay --noconfirm -S networkmanager net-tools network-manager-applet systemd-boot-pacman-hook wget"

# Enable services
systemctl enable NetworkManager.service
EOF

# Unmount and reboot
umount -R /mnt
reboot
