### Internet Check:
    ip a

### Connect to Wi-Fi at install:
    iwctl
    iwctl device list
    iwctl station stationname scan
    iwctl station stationname get-networks
    iwctl station stationname connect networkname

### Network Time Protocol sync:
    timedatectl set-ntp true

### Disk partitioning:
    gdisk/[disk name] (UEFI) - cfdisk/[diskname] (MBR)

### Format EFI and Root partitions: e.g.(ext4 Format)
    mkfs.fat -F32 /dev/[efi partition name] (UEFI only)
    mkfs.ext4 /dev/[root partiton name]
    mkswap /dev/[SWAP partition] (MBR only)
    swapon /dev/[SWAP partition] (MBR only)

### Mount partitions:
    mount /dev/[root partition name] /mnt
    mkdir /mnt/boot/efi (UEFI only)
    mount /dev/[efi partition name] /mnt/boot/efi (UEFI only)

### Base install:
    pacstrap /mnt base linux linux-firmware vim nano intel-ucode amd-ucode

### Generate the FSTAB file:
    genfstab -U /mnt >> /mnt/etc/fstab

### Enter the installation
    arch-chroot /mnt

### Swapfile (UEFI only):
    dd if=/dev/zero of=/swapfile bs=1G count=2 status=progress
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile

### Enter Swapfile to the FSTAB (UEFI only):
    vim /etc/fstab
    /swapfile none swap defaults 0 0

### Localization (replace accordingly to your Timezone):
    ln -sf /usr/share/zoneinfo/Asia/Chennai /etc/localtime
    hwclock --systohc
    nano /etc/locale.gen (uncomment the locale of your choice)
    locale-gen
    echo "LANG=your locale here" >> /etc/locale.conf

### Hostname and Hosts file:
    nano /etc/hostname (enter a name of your choice)
    nano /etc/hosts
    127.0.0.1 localhost
    ::1       localhost
    127.0.1.1 hostname.localdomain hostname (replace with your hostname) 

### Root password:
    passwd

### Bootloader and Networking tools:
    pacman -S grub efibootmgr networkmanager network-manager-applet dialog mtools dosfstools base-devel linux-headers reflector git bluez bluez-utils cups xdg-utils xdg-user-dirs pulseaudio-bluetooth

### Grub install UEFI:
    grub-install --target=x86_64-efi --efi-directory=/boot/ --bootloader-id=GRUB

### Grub install MBR:
    grub-mkconfig -o /boot/grub/grub.cfg

### Activate services for next reboot:
    systemctl enable NetworkManager
    systemctl enable bluetooth
    systemctl enable org.cups.cupsd

### Add user:
    useradd -mG wheel username (replace with yours)

### Create password for the user:
    passwd username (replace with yours)

### Give the user Sudo priviledges:
    EDITOR=nano visudo
    uncomment the %wheel all=(all) all

### Return to the installer, unmount all partitions and reboot:
    exit
    umount -a
    reboot

### Check for internet:
    ip a

### If on Wi-Fi connect with:
    nmtui
    
### Graphics card drivers for Intel, AMD and Nvidia cards:
    sudo pacman -S xf86-video-intl
    sudo pacman -S xf86-video-amdgpu
    sudo pacman -S nvidia nividia-utils
    
### Display server:
    sudo pacman -S xorg

### Display manager installation and activation: e.g.(sddm for kde)
    sudo pacman -S sddm
    sudo systemctl enable sddm
    
### Desktop Environment install: e.g.(Kde Plasma)
    sudo pacman -S plasma kde-applications packagekit-qt5

### OR

### Display manager installation and activation: e.g.(gdm for gnome)
    sudo pacman -S gdm
    sudo systemctl enable gdm

### Desktop Environment install: e.g.(gnome)
    sudo pacman -S gnome gnome-extra

### Install YAY: (optional)
    git clone https://aur.archlinux.org/yay.git
    cd yay/
    makepkg -si PKGBUILD
    
### Install Fonts: (optional)
    yay -S ttf-ms-fonts

### Install Timeshift: (optional)
    yay -S timeshift

### Enable Trim timer: (optional)
    sudo systemctl enable fstrim.timer



    
    
    
    
