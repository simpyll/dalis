# First check the internet connection.
ping google.com

# Sync clocks
timedatectl set-ntp true

# Create disk partitions using GPT.
# - /boot (EFI system partition)
# - SWAP (Linux swap)
# - /mnt (linux root x86-64)
cfdisk

# Format the newly made partitions.
# This command assumes that the partitions were made in the exact order above.
# You'll have to figure it out yourself.
mkfs.btrfs /dev/sda3
mkswap /dev/sda2

# Mount the file system.
mount /dev/sda3 /mnt

# Mount the swap partition.
swapon /dev/sda2

# Pacstrap the essentials.
# This installs the kernel and a few other essential packages
pacstrap /mnt base base-devel linux linux-firmware vim sudo grub dosfstools efibootmgr

# Generate fstab file.
genfstab -U /mnt >> /mnt/etc/fstab

# INSTALLATION PROCESS

# Change root into the new system.
# At this point, you are now configuring the system.
arch-chroot /mnt

# Install network management software.
pacman -Syu networkmanager
systemctl enable --now NetworkManager

# Install microcode packages.
# ONLY RUN THE RELEVANT COMMAND FOR CPU.
pacman -Syu intel-ucode

# Change timezone accordingly.
ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime
hwclock --systohc

# Edit locale-gen for the relevant timezone.
vim /etc/locale.gen
locale-gen

# Create a file for language.
# Add in LANG=en_US.UTF-8
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Create the hostname.
# Add in whatever hostname you want in there.
echo "arch" > /etc/hostname

# Set new root password.
passwd

# Creat a bootable mount point.
mkfs.fat -F32 /dev/sda1
mkdir /boot/EFI
mount /dev/sda1 /boot/EFI/

# Select boot loaders.
grub-install --target=x86_64-efi --bootloader-id=GRUB --removable --recheck
grub-mkconfig -o /boot/grub/grub.cfg

# Exit the chroot environment.
exit
umount -R /mnt
reboot


# POST INSTALL

# Add user and enable as sudoer.
# When in the sudoersfile, add the folling:
#  brian ALL=(ALL) ALL
# Log back in under david after this.
useradd -m david
passwd david
vim /etc/sudoers
exit

# Activate multilib repositories.
#   Uncomment the [multilib] section
sudo vim /etc/pacman.conf

# Install DEs and related tools.
# This is just GNOME, but pretty much anything ought to fit.
# After this point, the machine will boot into the DE.
sudo pacman -Syu xorg xorg-server xorg-server-xwayland
sudo pacman -Syu gnome
sudo systemctl enable --now gdm.service

# Install yay package management tool.
sudo pacman -Syu git openssh
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

# Install web browsers.
sudo pacman -Syu firefox chromium neofetch gnome-tweaks

# Remove some unwanted icons/packages.
sudo pacman -Rcns epiphany
sudo rm /usr/share/applications/avahi-discover.desktop
sudo rm /usr/share/applications/bsssh.desktop
sudo rm /usr/share/applications/bvnc.desktop
sudo rm /usr/share/applications/qv4l2.desktop
sudo rm /usr/share/applications/qvidcap.desktop
