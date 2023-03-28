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
usermod -aG wheel,audio,video,storage david

# uncomment wheel in visudo
# vim visudo

pacman -S --noconfirm xorg-server xorg-apps xorg-xinit xdg-user-dirs xorg sudo
pacman -S --noconfirm i3 i3-gaps i3blocks i3lock numlockx
pacman -S --noconfirm networkmanager network-manager-applet dhcpcd iw wpa_supplicant dialog openssh

systemctl enable sshd
systemctl enable dhcpcd
systemctl enable NetworkManager.service

pacman -S --noconfirm tlp tlp-rdw powertop acpi

systemctl enable tlp 
systemctl enable tlp-sleep
systemctl mask systemd-rfkill.service
systemctl mask systemd-rfkill.socket
