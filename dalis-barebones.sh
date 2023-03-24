# Install arch linux with as little as possible.
#
# ***IMPORTANT*** 
# This script assumes you are connected to the internet. 
# You can do so manually by using an ethernet cable (It is automatic. No scripting or other input needed.) 
#
# Or by using iwctl. Example: 
#
# iwctl device list
# iwctl station <stationname> scan
# iwctl station <stationname> get-networks
# iwctl station <stationname> connect <ssid> -P <password>


# Wipe file system and create two new partitions
sgdisk -Z -a 2048 -o /dev/sda -n 1::+512M -n 2::: -t 1:ef00 

timedatectl set-ntp true
timedatectl set-timezone America/Chicago

mkfs.fat -F32 /dev/sda1
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot 

mkfs.ext4 /dev/sda2
mount /dev/sda2 /mnt
