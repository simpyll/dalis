# Arch Installation guide
## :exclamation::exclamation: Note: Run maually

### After booting into arch iso

### Check if your computer uses BIOS or UEFI
#### NOTE: The following script is for BIOS
`ls /sys/firmware/efi/efivars`

### Connect to wireless
Not needed if connected via wired connection  
`wifi-menu`  
Check if transmitting data  
`ping google.com`  

### The following 3 commands are optional
#### Note: Sometimes running reflector may show error this can be fixed by updating the python package
`pacman -Syu`

`pacman -S reflector`

`reflector --latest 6 --protocol http --protocol https --sort rate --save /etc/pacman.d/mirrorlist`

### Update system clock
`timedatectl set-ntp true`

### Partitioning
Use appropriate partitionig tool fdisk/cfdisk etc...
Current tool cfdisk
### Partition tips: 
#### boot - 200M
#### swap - default (optional)
#### root - choose more than 20
#### home - rest of the disk
### Note: Can also choose only one partion as root.

#### Note the naming of ur drive /dev/sda or /dev/sdb etc... using the following command
`lsblk`

### For /boot /home and /root
`mkfs.ext4 /dev/sda(partition number of boot)`

`mkfs.ext4 /dev/sda(partition number of home)`

`mkfs.ext4 /dev/sda(partition number of root)`

### For swap (optional can make additional swap file as needed)
`mkswap /dev/sda(partition number of swap)`

`swapon /dev/sda(partition number of swap)`

### Mounting partitons
`lsblk`

`mount /dev/sda/(partition number of root) /mnt`

`cd /mnt`

`mkdir home boot`

`cd`

`mount dev/sda/(partition number of boot) /mnt/boot`

`mount dev/sda/(partition number of home) /mnt/home`

### Check if partitions are correctly mounted
`lsblk`

### Install system
#### Required
`pacstrap /mnt base linux linux-firmware`
#### Recommended
`pacstrap /mnt base base-devel linux linux-firmware networkmanager vim(or other editor)`
#### If dual booting also install os-prober and ntfs-3g
`pacstrap /mnt base base-devel linux linux-firmware networkmanager vim os-prober ntfs-3g`

### Generate fstab for your partitions
`genfstab -U /mnt >> /mnt/etc/fstab`

### chroot into your installed system
`arch-chroot /mnt`

### Set your timezone
`ln -sf /usr/share/zoneinfo/(choose your timezone by pressing tab) /etc/localtime`

### Localization

### Open locale.gen file using your prefered editor
#### Search for `en_US.UTF-8 UTF-8` and `en_US ISO-8859-1` uncomment these two lines.
`vim /etc/locale.gen`
#### Update locale.gen
`locale-gen`

### Open locale.conf file using your prefered editor
#### Set your language
`vim /etc/locale.conf`
### Type the following in the file
`LANG=en-US.UTF-8`

### Set Hostname(name for your pc)
#### Initially blank file
`vim /etc/hostname`  and `vim /etc/hosts`
#### Type your hostname in the file
`(your hostname)`

### Set password for root
type `passwd`

### Install and enable Network Manager
`pacman -S networkmanager`

`systemctl enable NetworkManager`

### :exclamation:Grub
`pacman -S grub`

`grub-install /dev/sda`

### :exclamation:Make grub configuration file
`grub-mkconfig -o /boot/grub/grub.cfg`
#### Note: If windows is not detected install grub again from system

### Exit chroot
`exit`

### Unmount partitions
`umount -R /mnt`

#### Reboot
`reboot`

## After rebooting
#### Login as root and your set password

### Create new user
`useradd -m -g wheel (your username)`

### Set user password 
#### Note: This is different from `root` password
`passwd (your username)`

### Give sudo access to user
#### Edit your sudoers file
`vim /etc/sudoers`
#### Uncomment the line `%wheel ALL =(ALL) ALL` 
To run specific commands without having to enter your password add the path to command after the above line in sudoers eg: `%wheel ALL =(ALL) NOPASSWD: /usr/bin/shutdown,/usr/bin/reboot,/usr/bin`

After this your new user is created and you can login using your set username and password
Type `exit` to logout

### Graphical environment
`pacman -S xorg-server xorg-xinit`
You can start X by running `xinit` or `startx` will read from ~/.xinitrc

### Window manager
`pacman -S i3-gaps i3status (or) i3blocks`
Make the server start i3 when starts. In ~/..xinitrc, put: `exec i3`

### Terminal emulator
`pacman -S rxvt-unicode`

### Menu for i3
`pacman -S dmenu (or) rofi`

### Also install
Network manager (nm-applet)

#### Remove installation media and boot up Arch Installation
Login as username (your username) and your password (password for your username)

### Run the following when booting from your installed system

### Note: 
##### Changing your tty: 
Try pressing Ctrl + F1/2/3/... and Alt + Left/Right to move accross ttys

##### Start a service at every startup
`sudo systemctl enable SERVICENAME`
##### Start a service right now
`sudo systemctl start SERVICENAME`

##### Execute something or some commands after login(Startup applications etc...)
Edit the file ~/.profile or ~/.bash_profile

#### Start i3 automatically(edit ~/.profile)
```
if[[ "$(tty)" = "/dev/tty1" ]]; then
    pgrep i3 || startx
fi
```
                                 
