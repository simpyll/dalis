sgdisk -Z -a 2048 -o /dev/sda -n 1::+512M -n 2::: -t 1:ef00 

timedatectl set-ntp true
timedatectl set-timezone America/Chicago

mkfs.fat -F32 /dev/sda1
mkdir -p /mnt/boot 
mount /dev/sda1 /mnt/boot 

mkfs.ext4 /dev/sda2
mount /dev/sda2 /mnt

pacstrap /mnt base base-devel linux linux-firmware intel-ucode openssh vim

genfstab -U /mnt > /mnt/etc/fstab
