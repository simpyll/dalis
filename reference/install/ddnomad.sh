###############################################################################
# Author: ddnomad
# Version: 1.1.3
# Last Update: 2020-07-06
#
# External contributors:
#   - u/momasf (https://www.reddit.com/user/momasf) - an excellent
#     tip to use 'reflector' to speed up downloads during the base
#     installation
#   - eXhumer (https://github.com/eXhumer) - Fixes for things that
#     have changed since 2018.
#   - BasuDivergence (https://gist.github.com/BasuDivergence) - Note
#     on installing lvm2 package before running mkinitcpio; various
#     useful suggestions to simplify the flow.
#   - wcasanova (https://github.com/wcasanova) - Suggestion to move
#     lvm2 package installation to all other pacstrap packages in
#     step 4. Suggestion to include a link to Arch Wiki comparison
#     between different full system encryption approaches.
#
# Choosing between LVM on LUKS vs LUKS on LVM (this guide only covers
# the latter):
#   - https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system#Overview
#
# Similar guides:
#   - https://gist.github.com/huntrar/e42aee630bee3295b2c671d098c81268
#
# DISCLAIMER/WARNING: Some people on r/archlinux were not quite happy
# with this guide mostly due to the fact it encourages a reader to
# blindly enter keystrokes and commands without understanding how
# things work.
#
# I cannot agree more and that is why I DO ENCOURAGE THE READER TO
# READ THE F***ING WIKI. This guide should be used as a reference
# point, not as a dogma. Bear in mind that things might get wrong
# due to some machine-specific gotchas and the only place where the
# reader can get all the necessary info is Arch Wiki.
###############################################################################

# This guide shows how to install Arch Linux with a full-disk encryption
# method called "LUKS on LVM" (powered by dm-crypt). It should work just 
# fine for both a single physical disk (HDD/SSD) and a couple of them.
#
# The steps are verified to be valid as of 2018-09-15 and were composed
# according to the following sources (with minor fixes in 2020 added by
# eXhumer):
#   - https://wiki.archlinux.org/index.php/installation_guide
#   - https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system
#   - https://wiki.archlinux.org/index.php/Category:Boot_loaders
#   - https://wiki.archlinux.org/index.php/Microcode
#
# Assumptions:
#   - A boot media (say, USB drive) was alread prepared and the reader 
#     has already booted from the media into virtual console
#   - Using only US keymap
#   - Motherboard has UEFI mode enabled

# STEP 0: Wiping the disks
# ========================
# Encryption should be done only after all physical disks were securely
# wiped. There are a plenty of options but the one I'd suggest is to
# use Parted Magic (duck it). A current version of the program costs
# around $10 though it is completely worth it.
#
# Alternative (free) approaches can be found here:
# https://wiki.archlinux.org/index.php/Securely_wipe_disk

# STEP 1: Verify UEFI mode is enabled
# ===================================
# Run this command to verify that UEFI mode is enabled. If it exits with
# an error refer to Arch Linux Installation Guide to make things working.
ls /sys/firmware/efi/efivars

# STEP 2: Connect to the internet and setup time
# ==============================================
# There are a couple of options:
#   - Ethernet should just work if you plugged the holy RJ-45 before
#     turning on your host. If not you're on your own :D
#   - For WPA2/WPA or public hotspots (please avoid them) the reader
#     can just run "wifi-menu", choose a hotspot and enter the
#     password if necessary
#   - For WPA-Enterprise you'd probably need a custom configuration
#     file so good luck finding one.
#
# The below should give you a bunch of lines metioning "64 bytes"
ping archlinux.org

# Unsure system clock is accurate
timedatectl set-ntp true

# This should show a correct time
timedatectl status

# STEP 3: Disk partitioning and LVM/LUKS setup
# ===========================================
# Run this and identify disks that you want to install Arch Linux on
lsblk

# This should yield a couple of candidates like /dev/sda (SATA/USB
# interface, mostly HDDs or flesh drives) or like /dev/nvme0n1
# (mostly SSD disks).
#
# Now the reader have to decide whether to "merge" several disks
# into a single logical one with a help of LVM. An optional step
# for that will be explicitly mentioned.

# Determine the main disk where /boot partition will reside. Say,
# it is /dev/sda (most probably it will have the same name).
#
# Now the reader have to partition it properly. We need two
# partitions: the one for /boot and the other for LVM group.
#
# Adjust partition sizes according to a total amount of space
# target disk[s] have.

# Open partitioning tool
fdisk /dev/sda

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

# You can use any name instead of 'PrimVolGroup' here
vgcreate PrimVolGroup /dev/sda2

# (Optional): Here if you have a couple of physical disks that
# you want to treat as a single logical disk and use for Arch
# installation. The downside would be that if one of the disks
# went bananas you'd lose the data on the second disk as well.
#
# Though it is quite useful and essentially vital to do if you
# want to setup encryption spanning all disks without much of
# a pain.
#
# These steps should be done for each additional physical disk
# you want to "merge" with PrimVolGroup created above.
#
# STEP 3(o1): Adding a second disk to the volume group
# ---------------------------------------------------
#
# Say, a second disk you want to setup is /dev/sdb. Then you
# have to use fdisk once again:
fdisk /dev/sdb

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
pvcreate /dev/sdb1
vgextend PrimVolGroup /dev/sdb1

# Verify that a total size of the volume group is
# correct (check a 'VG Size' field):
vgdisplay

# STEP 3(o1): ENDED HERE

# After the reader extended the volume group (that
# was optional) we need to create LVM volumes for
# each essential partition: /root, swap, /tmp and
# /home. Again, adjust volume sizes to your liking
# (the list 100%FREE stuff means you allocate all
# remaning free space to /home).
#
# Labels 'cryptroot', 'cryptswap' etc can be changed
# to whatever names the reader prefers though I would
# not suggest doing that. You might get confused
# because of the names you've chosen in the future
# (I know that because I did that).
#
# Also I'd advise not cheaping out on /root partition
# size. Just to avoid "running out of space" stuff when
# using Docker or just updating packages without cleaning
# cache. 100G is doable though I like it big :X
lvcreate -L 500G -n cryptroot PrimVolGroup

# Size of swap partition should be the same as an
# amount of RAM your host has. It's not like "mandatory"
# but is defenitely a good thing to do.
lvcreate -L 64G -n cryptswap PrimVolGroup

# /tmp volume
lvcreate -L 20G -n crypttmp PrimVolGroup

# And finally /home
lvcreate -l 100%FREE -n crypthome PrimVolGroup

# Neat. Now let's encrypt /root partition. This one will prompt
# you for an encryption passphrase. Please use a decent 15+
# characters passphrase (with special characters and numbers,
# mixed case). Make sure to save the passphrase in a password
# manager of your choice or whatever.
#
# You won't have to enter the passphrase more often then once
# per boot so make it complex.
cryptsetup luksFormat --type luks2 /dev/PrimVolGroup/cryptroot

# This will prompt for the passphrase you just entered:
cryptsetup open /dev/PrimVolGroup/cryptroot root

# Now finally format the partition and mount it
mkfs.ext4 /dev/mapper/root
mount /dev/mapper/root /mnt

# STEP 4: Base installation
# =========================
# Now we have a root partition ready to throw some Arch Linux
# stuff in there. But first we need to enable swap partition:
mkswap /dev/PrimVolGroup/cryptswap
swapon /dev/PrimVolGroup/cryptswap

# Mount /boot as well as we're going to setup
# bootloader later on:
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

# (Optional) Use reflector to speedup download (credit goes to u/momasf)
# https://www.reddit.com/r/archlinux/comments/9g6fmq/arch_linux_installation_with_a_fulldisk/e621ete
# Change COUNTRY to (surprise) your country name.
pacstrap /mnt reflector
reflector --country 'COUNTRY' --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# Install base packages and bootstrap the system. That will
# download the kernel and all other packages to make your
# Arch installation working afterwards (hopefully :D).
#
# NOTE: This is up-to-date with 2020 thanks to eXhumer
# as in 2018 pacstrapping 'base' and 'base-devel' was
# enough.
#
# lvm2 package installation was moved here from step 5
# following a suggestion from wcasanova.
pacstrap /mnt base linux linux-firmware lvm2 mkinitcpio

# Chroot into a freshly bootstrapped system
arch-chroot /mnt

# Setup time zone (swap REGION and CITY for your actual
# region and city obviously, say, REGION=Europe and
# CITY=Paris)
ln -sf /usr/share/zoneinfo/REGION/CITY /etc/localtime

# Set hardware clock and update timestamps
hwclock --systohc

# Uncomment needed locales (i.e. en_US.UTF-8 UTF-8). By
# uncommenting is meant a removal of leading '#' character
# in the very beginning of a line with a locale the reader
# wants to enable.
#
# (you can use 'nano' instead of 'vi' for editing if you're
# not into trying to figure out how to exit vi)
vi /etc/locale.gen

# Generate locales
locale-gen

# Set LANG variable in /etc/locale.conf accordingly (credit
# goes to BasuDivergence for simplifying this step):
locale > /etc/locale.conf

# The above also can be done by editing /etc/locale.conf
# directly using the following command: vi /etc/locale.conf
# Example for en_US.UTF-8 UTF-8 locale: "LANG=en_US.UTF-8"

# Set a hostname (think of something fancy, say, 'arch' :D)
#
# The file should contain a single word which is a hostname
# of your choice.
vi /etc/hostname

# Modify /etc/hosts accordingly
#
# Example ('^' char signifies a beginning of a line and should
# be omitted from an actual file, HOSTNAME should be swapped
# for a word you typed in /etc/hostname):
# ^127.0.0.1  localhost
# ^::1        localhost
# ^127.0.0.1 HOSTNAME.localdomain HOSTNAME
vi /etc/hosts

# Set a root password. Again, make sure the password is complex
# and was saved to a place where only the reader (you!) is able
# to find and access it. The command below will prompt you to
# enter the actual password.
passwd

# STEP 5: mkinitcpio and /etc/*tab configuration
# =========================================================
# In order to make Arch prompting for a password during boot
# we need to modify mkinitcpio hooks a bit. Make sure the line
# that starts with ^HOOKS= matches the one below (again, '^'
# character should be omitted from an actual file)
#
# ^HOOKS=(base udev autodetect keyboard keymap consolefont modconf block lvm2 encrypt filesystems fsck)
vi /etc/mkinitcpio.conf

# Modify /etc/cryttab to match the example below with necessary
# changes for the reader's naming (and remove '^' char):
#
# ^swap /dev/PrimVolGroup/cryptswap /dev/urandom swap,cipher=aes-xts-plain64,size=256
# ^tmp  /dev/PrimVolGroup/crypttmp  /dev/urandom tmp,cipher=aes-xts-plain64,size=256
# ^home /dev/PrimVolGroup/crypthome /etc/luks-keys/home
vi /etc/crypttab

# For those who are curious the step above will ensure
# that both /tmp and swap partitions will be encrypted
# and wiped during each next boot.

# Modify /etc/fstab. Don't worry, /home encryption will happen in the
# next steps.
#
# Should be (remove '^' char, make sure '/dev/sda1' is the boot partition):
# ^/dev/mapper/root /     ext4  defaults 0 1
# ^/dev/sda1        /boot vfat  defaults 0 2
# ^/dev/mapper/home /home ext4  defaults 0 2
# ^/dev/mapper/tmp  /tmp  tmpfs defaults 0 0
# ^/dev/mapper/swap none  swap  sw       0 0
vi /etc/fstab

# Now it is necessary to regenerate initramfs
mkinitcpio -p linux

# STEP 6: Bootloader setup
# ========================
# We are going to use systemd-boot as a bootloader for this
# installation. If the reader objects, he is free to setup
# any other bootloader himself.
bootctl --path=/boot install

# We need this package to enable microcode updates
# For AMD CPUs install 'amd-ucode' package instead
pacman -S intel-ucode

# Suggestion by BasuDivergence (seems to be a recommended step):
#
# Create / add the main bootloader configuration file with the
# following lines in it (remove a leading '^'):
# ^default arch
# ^timeout 5
# ^editor=0
vi /boot/loader/loader.conf

# Create a bootloader configuration file:
#
# It should look like this (remove '^', adjust options to the
# reader's naming scheme, '/amd-ucode.img' for AMD CPUs):
# ^title Arch Linux
# ^linux /vmlinuz-linux
# ^initrd /intel-ucode.img
# ^initrd /initramfs-linux.img
# ^options cryptdevice=/dev/PrimVolGroup/cryptroot:root root=/dev/mapper/root rw
vi /boot/loader/entries/arch.conf

# Optionally install dependencies of wireless network interfaces
# (otherwise you won't be able to use wifi-menu and netctl after
# reboot). THIS IS IMPORTANT :X
pacman -S wpa_supplicant dialog

# STEP 6: Encryption /home
# ========================
# We are almost done! The only thing that is left is to encrypt
# /home logical volume.
mkdir -m 700 /etc/luks-keys
dd if=/dev/random of=/etc/luks-keys/home bs=1 count=256 status=progress

# For those who are curious (again!) the above generates a random
# passphrase which will be used in /home encryption and saves it
# in /etc/luks-keys/home file.
#
# So we need to remeber only a single encryption passhprase from /root
# partition and we'll now setup automatic decryption of /home using
# the key from decrypted during boot /root partition. Cool, right?

# Encrypt /home volume
cryptsetup luksFormat --type luks2 -v /dev/PrimVolGroup/crypthome /etc/luks-keys/home
cryptsetup -d /etc/luks-keys/home open /dev/PrimVolGroup/crypthome home
mkfs.ext4 /dev/mapper/home

# STEP 7: Pray to Linus
# =====================
# Type in the following
exit
reboot now

# Unplug the boot media!
# Now hope that everything was set up correctly.

# STEP 8: HOORAY!
# You did it! (probably)

# The Linux philosophy is 'Laugh in the face of danger'. 
# Oops. Wrong One. 
# 'Do it yourself'.
# Yes, that's it.
#
# (c) Linus Torvalds

# So you finished the guide, right? Cool!
# Thank you for your interest in this guide.
#
# Things to do:
#   - https://wiki.archlinux.org/index.php/General_recommendations
#   - https://wiki.archlinux.org/index.php/dm-crypt -- read what you just did
#
# Social:
#   - Reach me out: https://www.reddit.com/user/ddnomad
#   - Found a typo? A ~bug~ feature? Wanna add something? Just ping me and we
#     can talk this through.
