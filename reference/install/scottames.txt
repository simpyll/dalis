# Arch Install

## tl;dr

Included in install:

* Gnome Shell
* Luks disk encryption w/ logical volumes
* Systemd _or_ Grub boot for EFI

## Prepare / Boot

### In live usb

Optionally increase terminal font

```shell
# sync package database
pacman -Syy
# install a font (terminus in this case)
pacman -S terminus-font
# enable
setfont ter-v32n
# or
setfont sun12x22
```

Sync the clock

```shell
timedatectl set-ntp true
```

## Install

### Network

#### Wifi

Use: `iwctl`

```shell
device list #to check the device name
station <device-name> scan #to scan the wifi
station <device-name> get-networks #to check the available networks
station <device-name> connect <wifi-name> #and then enter the password if there's any
exit #exit iwctl
```

```shell
ping archlinux.org
```

Optionally enable ssh & connect from remote machine

```shell
# set root password
passwd
# enable sshd
systemctl enable --now sshd
```

### Update the System Clock

```shell
timedatectcl set-ntp true
```

### Disk

Partition disk

1. EFI

    ```shell
    # Size: 100M, Hex Code: ef00, Name: ESP
    mkfs.vfat -F32 /dev/sda1
    ```

2. Linux

    ```shell
    # Size: default (remaining space), Hex Code: default (8300), Name: Storage
    # no need need to format
    ```

#### Encryption

* Enable: `modprobe dm-crypt`
* Replace `/dev/sda2` with the appropriate partition

```shell
cryptsetup --cipher aes-xts-plain64 --key-size 512 --hash sha512 luksFormat /dev/sda2
```

Open it

```shell
cryptsetup luksOpen /dev/sda2 arch
```

#### Volumes and Mounts

Set up the root volume & swap

```shell
# Create volumes
pvcreate /dev/mapper/arch
vgcreate vol /dev/mapper/arch
lvcreate --size 16G vol --name swap
lvcreate -l +100%FREE vol --name root
# Format volumes
mkfs.ext4 /dev/mapper/vol-root
mkswap /dev/mapper/vol-swap
# mount it
mount /dev/mapper/vol-root /mnt
# boot
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot
swapon /dev/mapper/vol-swap
```

### Install the System

#### Retrieve the Latest Mirror List

```shell
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.orig
```

```shell
reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
```

#### Install

```shell
# Pacstrap system
pacstrap -i /mnt \
            base \
            base-devel \
            dialog \
            dhcpcd \
            efibootmgr
            git \
            gnome \
            intel-ucode \
            linux \
            linux-firmware \
            lvm2 \
            mkinitcpio \
            networkmanager \
            nm-connection-editor \
            network-manager-applet \
            vim \
            wpa_supplicant \
            zsh
```

```shell
# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab
# Confirm & make any changes
vim /mnt/etc/fstab
```

chroot into new system

```shell
# chroot into system
arch-chroot /mnt /bin/bash
```

#### In chroot

##### Clock

```shell
# Set timezone
ln  -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
timedatectl set-timezone America/Los_Angeles
# Sync clock
hwclock --systohc --utc
```

##### Hostname

```shell
# Set hostname
echo myhostname > /etc/hostname
hostnamectl set-hostname myhostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 myhostname" >> /etc/hosts
```
##### User

```shell
# Create a user
useradd -m -g users -G wheel -s /bin/zsh <USER>
passwd myuser
```

```shell
# Add user to sudoers (via wheel or whatever desired mechanism, recommended: `%wheel ALL=(ALL) ALL`)
# visudo
perl -i -pe 's/# (%wheel ALL=\(ALL\) ALL)/$1/' /etc/sudoers
# Set a rediculous password for root
passwd -l root
```

##### Locale

```shell
# Edit locals
vim /etc/locale.gen
# uncomment en_US.UTF-8 UTF-8
echo LANG=en_US.UTF-8 > /etc/locale.conf
echo LANGUAGE=en_US >> /etc/locale.conf
locale-gen
```

```shell
# Make appropriate changes to mkinitcpio
vim /etc/mkinitcpio.conf
## edit HOOKS
### e.g. `HOOKS=(base udev autodetect modconf block keymap keyboard encrypt lvm2 resume filesystems fsck)`
# save changes & run
mkinitcpio -p linux
```

```shell
# Install a couple patches (Not applicable for all razer systems)
cd /tmp/
chown -R myuser tmp/
su <USER> -
git clone https://aur.archlinux.org/aic94xx-firmware.git
git clone https://aur.archlinux.org/wd719x-firmware.git
cd aic94xx-firmware/
makepkg -sri
cd ../wd719x-firmware
makepkg -sri
# Install bootctl
mkinitcpio -p linux
# Enable dhcp + gdm
systemctl enable dhcpcd
systemctl enable NetworkManager
systemctl enable gdm
```

##### Configure Boot

###### Systemd

```shell
bootctl --path=/boot/ install
# Confirm & make any necessary changes to boot loader (use disk UUID)
blkid /dev/sda2
vim /boot/loader/loader.conf
```

Create arch entry

```shell
vim /boot/loader/entries/arch.conf
```

Add the following:

```
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options cryptdevice=UUID=[uuid_of_root_partition]:vol resume=/dev/mapper/vol-swap root=/dev/mapper/vol-root quiet rw
```

Optionally, create a Windows entry:

```shell
vim /boot/loader/entries/windows.conf
```

```
title Windows
efi /EFI/Microsoft/Boot/bootmgfw.efi
```

```shell
bootctl --path=/boot install && \
bootctl --path=/boot update && \
bootctl list && \
bootctl
```

###### Grub

```shell
pacman -S grub
grub-install --target=x86_64-efi --efi-directory=/boot --recheck
```

Edit `/etc/default/grub` and set the line:

```shell
GRUB_CMDLINE_LINUX="cryptdevice=/dev/nvme0n1p3:vol:allow-discards"
```

Generate the Grub config

```shell
grub-mkconfig -o /boot/grub/grub.cfg
```

## Cleanup & Reboot

```shell
# exit chroot
exit
# unmount stuffz
umount /mnt/boot
umount /mnt
swapoff -a
```

Cross your fingers...

```shell
reboot
```

## Resources

* [Arch Linux Install Guide - EFI & LVM & LUKS - TurluCode](https://turlucode.com/arch-linux-install-guide-efi-lvm-luks/)
* [dm-crypt/Encrypting an entire system - ArchWiki](https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system)
* [ArchLinux Tutorial, Part 1: Basic ArchLinux Installation](https://medium.com/@mudrii/arch-linux-installation-on-hw-with-i3-windows-manager-part-1-5ef9751a0be)
* [Install Arch Linux on a Dell XPS 13 9310 with Disk Encryption](https://chrislea.com/2021/01/29/install-arch-linux-on-a-dell-xps-13-9310-with-disk-encryption/)

## Packages

Update database cache

```shell
pacman -Syy
```


Install [paru](https://github.com/Morganamilo/paru)

```shell
sudo pacman -S --needed base-devel
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
```

Install lots o stuff :D

```shell
paru -S --needed alsa-firmware \
        alsa-utils \
        android-tools \
        ansible \
        asciidoc \
        atom \
        awesome-terminal-fonts \
        aws-cli \
        aws-session-manager-plugin \
        bash-completion \
        bc \
        bind-tools \
        bitwarden-bin \
        boostnote-bin \
        brave-bin \
        brother-mfc-j870dw \
        capitaine-cursors \
        chrome-gnome-shell \
        circleci-cli-bin \
        code \
        cups \
        cups-filters \
        dbeaver \
        debtap \
        deluge \
        dep \
        docker \
        docker-compose \
        firefox \
        flameshot \
        flat-remix-git \
        flatpak \
        fzf \
        gimp \
        gitkraken \
        gnome-common \
        gnome-extra \
        gnome-notes \
        gnome-shell-extension-dash-to-dock \
        gnome-shell-extension-emoji-selector-git \
        gnome-shell-extension-radio-git \
        gnome-shell-extension-topicons-plus \
        gnome-shell-extension-window-corner-preview-git \
        gnome-subtitles \
        gnome-system-log \
        gnome-tweaks \
        gnu-netcat \
        go \
        gobject-introspection \
        godep \
        goland \
        goland-jre \
        google-chrome \
        gparted \
        gpg-crypter \
        graphicsmagick \
        graphviz \
        gufw \
        hidapi \
        htop \
        http-parser \
        hub \
        insync \
        iotop \
        itstool \
        jetbrains-toolbox \
        jq \
        keybase \
        keybase-gui \
        kubectl-bin \
        libreoffice-fresh \
        lshw \
        lsof \
        mackup \
        neofetch \
        nerd-fonts-complete \
        networkmanager-openvpn \
        nmap \
        nodejs \
        notify-send.sh \
        noto-fonts \
        noto-fonts \
        noto-fonts-emoji \
        noto-fonts-extra \
        npm \
        openvpn \
        p7zip \
        packer \
        pinta \
        postman-bin \
        powerline-common \
        powerline-fonts \
        psensor \
        python-aws-mfa \
        python-pip \
        redshift \
        remake \
        rsync \
        ruby \
        rubygems \
        saw \
        screenfetch \
        shellcheck \
        spaceship-prompt-git \
        speedtest-cli \
        spotify \
        sublime-text-dev \
        tflint-bin \
        tilix \
        tmate \
        tmux \
        ttf-caladea \
        ttf-carlito \
        ttf-croscore \
        ttf-crosextra \
        ttf-dejavu \
        ttf-fira-mono \
        ttf-fira-sans \
        ttf-font-logos \
        ttf-google-fonts-git \
        ttf-inconsolata \
        ttf-input \
        ttf-liberation \
        ttf-merriweather \
        ttf-merriweather-sans \
        ttf-ms-fonts \
        ttf-openlogos-archupdate \
        ttf-opensans \
        ttf-oswald \
        ttf-quintessential \
        ttf-roboto \
        ttf-signika \
        ttf-ubuntu-font-family \
        ufw \
        ufw-extras \
        gufw \
        ufw-icon-bar \
        unrar \
        usbguard \
        wavebox-bin \
        wget \
        xclip \
        yamllint \
        yq \
        yubico-c \
        yubico-c-client \
        yubikey-manager \
        yubikey-personalization \
        zoom \
        zsh-pure-prompt
```

If `grub` is installed

```shell
paru -S grub-hook
```

### Optional

#### Razer utils & drivers

```shell
paru -S openrazer \
    openrazer-meta \
    polychromatic \
    razergenie \
    chroma-feedback \
    razercommander
```

#### Terraform

```shell
git clone https://github.com/tfutils/tfenv.git ~/.tfenv
tfenv install latest
```

#### Battery

```shell
paru -S tlp
```

## Dotfiles

1. Clone
2. Symlink to ~/.dotfiles
3. `ln -s ~/.dotfiles/.mackup.cfg ~/.mackup.cfg`
4. `mackup restore`

## Security

See: [Security - ArchWiki](https://wiki.archlinux.org/index.php/Security)

### Disable user from being listed at login

```shell
sudo vim /var/lib/accountsservice/users/<user>
```

Edit

```
SystemAccount=true
```

### Firewall

Enable ufw

```shell
sudo systemctl enable --now ufw
sudo ufw enable
```

Enable PCSD for Yubikey

```shell
sudo systemctl enable pcscd.socket --now
```

## Tweaks

Enable “Infinality mode” in plain vanilla freetype2

```shell
echo 'export FREETYPE_PROPERTIES="truetype:interpreter-version=38"' | sudo tee -a /etc/profile.d/freetype2.sh
cd /etc/fonts/conf.d
sudo ln -s ../conf.avail/10-hinting-slight.conf
sudo ln -s ../conf.avail/10-sub-pixel-rgb.conf
sudo ln -s ../conf.avail/11-lcdfilter-default.conf
cd ~
```

## Tweaks

Keyboard shortcut for screen rotation

* Sets ctrl + f8 to rotate the screen counter-clockwise

```shell
gsettings set org.gnome.mutter.keybindings rotate-monitor "['XF86RotateWindows', '<Control>F8']"
```
