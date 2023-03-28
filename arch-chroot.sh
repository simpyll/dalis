echo "KEYMAP=us" > /etc/vconsole.conf
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
ln -s /usr/share/zoneinfo/America/Chicago /etc/localtime
locale-gen
hwclock --systohc --utc

echo "127.0.0.1 localhost
::1 localhost
127.0.1.1 arch.localdomain arch" >> /etc/hosts

echo "arch" > /etc/hostname

passwd 

useradd -m David 
passwd david
usermod -aG wheel,audio,video,storage david'

# uncomment wheel in visudo
# vim visudo
