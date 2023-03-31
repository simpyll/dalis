#!/usr/bin/env bash

# Basic arch install script.
# - assumes network is already up
# - gpt -> luks -> ext4 root
# - swapfile /swap
# - systemd-boot
# - nftables
# - networkmanager

set -e

if [ $# -le 3 ]; then
    echo "Usage: $0 [hostname] [device] [username] [swapsize]"
    exit 1
fi

HOSTNAME=$1
DEVICE=$2
USERNAME=$3
SWAPSIZE=$4

PACKAGES_BOOTSTRAP="base linux linux-firmware"
PACKAGES_CHROOT="sudo networkmanager nftables vim"

timedatectl set-ntp true

parted --script "${DEVICE}" -- \
  mklabel gpt \
  mkpart ESP 1Mib 513MiB \
  mkpart primary 513MiB 100% \
  set 1 boot on

PART_BOOT="$(ls "${DEVICE}"* | grep -E "^${DEVICE}p?1$")"
PART_LUKS="$(ls "${DEVICE}"* | grep -E "^${DEVICE}p?2$")"

echo "Set LUKS password for ${PART_LUKS}"
cryptsetup luksFormat $PART_LUKS
cryptsetup luksOpen $PART_LUKS cryptroot

UUID_LUKS="$(blkid ${PART_LUKS} -o value -s UUID)"

mkfs.fat -F32 $PART_BOOT
mkfs.ext4 /dev/mapper/cryptroot

mount /dev/mapper/cryptroot /mnt
mkdir /mnt/boot
mount $PART_BOOT /mnt/boot

fallocate -l ${SWAPSIZE} /mnt/swap

chmod 600 /mnt/swap
mkswap /mnt/swap
swapon /mnt/swap

pacstrap /mnt $PACKAGES_BOOTSTRAP

genfstab -U /mnt > /mnt/etc/fstab

echo "$HOSTNAME" > /mnt/etc/hostname
echo -e "127.0.0.1\tlocalhost\n127.0.1.1\t${HOSTNAME}.localdomain ${HOSTNAME}\n::1\tlocalhost" > /etc/hosts
echo "en_US.UTF-8 UTF-8" > /mnt/etc/locale.gen
echo "KEYMAP=us" > /mnt/etc/vconsole.conf
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf

arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
arch-chroot /mnt locale-gen
arch-chroot /mnt pacman --noconfirm -Sy $PACKAGES_CHROOT
arch-chroot /mnt bootctl --path=/boot install

echo -e "title\t${HOSTNAME}\nlinux\t/vmlinuz-linux\ninitrd\t/intel-ucode.img\ninitrd\t/initramfs-linux.img\noptions\trd.luks.name=${UUID_LUKS}=cryptroot root=/dev/mapper/cryptroot rw quiet splash" > /mnt/boot/loader/entries/"${HOSTNAME}".conf
echo -e 'MODULES=()\nBINARIES=()\nFILES=()\nHOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt filesystems fsck)\nCOMPRESSION="zstd"' > /mnt/etc/mkinitcpio.conf
echo -e "root\tALL=(ALL) ALL\n${USERNAME}\tALL=(ALL) ALL" > /mnt/etc/sudoers
echo -e "[Time]\nNTP=0.europe.pool.ntp.org 1.europe.pool.ntp.org 2.europe.pool.ntp.org 3.europe.pool.ntp.org" > /mnt/etc/systemd/timesyncd.conf
echo "#!/usr/bin/nft -f
flush ruleset
table inet filter {
  chain input {
    type filter hook input priority 0
    policy drop
    iifname lo accept
    ct state { established, related } accept
    ct state { invalid } drop
    icmp type echo-request accept
    meta l4proto ipv6-icmp accept
  }
  chain forward {
    type filter hook forward priority 0
    policy drop
  }
  chain output {
    type filter hook output priority 0
    policy accept
  }
}" > /mnt/etc/nftables.conf

arch-chroot /mnt systemctl enable nftables
arch-chroot /mnt systemctl enable systemd-timesyncd
arch-chroot /mnt systemctl enable NetworkManager

echo "Set password for root user"
arch-chroot /mnt passwd

echo "Set password for ${USERNAME}"
arch-chroot /mnt useradd -m "$USERNAME"
arch-chroot /mnt passwd "$USERNAME"

arch-chroot /mnt mkinitcpio -p linux
