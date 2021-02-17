#!/bin/bash
declare ROOT_PASSWORD="password0"
declare USERNAME="username"
declare USR_PASSWORD="password1"
declare HOST_NAME="host name"
declare PARTITION_NAME="Arch Linux"
declare PARTITION_DEVICE="/dev/nvme0n1p4"
declare ESP_NAME="Arch Boot"
declare ESP_DEVICE="/dev/nvme0n1p3"
declare REGION="America"
declare CITY="Denver"
declare BOOTMANAGER=$1

# set bootmanager flag
if [ $BOOTMANAGER == "systemd" ];then
    declare BOOTMANAGER=0
elif [ $BOOTMANAGER == "grub" ];then
    declare BOOTMANAGER=1
else
    echo "Usage: install_arch [systemd | grub]"
    exit 1
fi

# format the main partition and mount it
echo "ARCH_INSTALL:: Unmounting, formatting, and remounting ${PARTITION_DEVICE}..."
umount -q $ESP_DEVICE # just in case part 1
umount -q $PARTITION_DEVICE # just in case part 2
mkfs.ext4 -q -L "$PARTITION_NAME" $PARTITION_DEVICE
mkdir -p /mnt/boot
mount $PARTITION_DEVICE /mnt

# set up pacman keys
# TODO fix broken pacman config process
echo "ARCH_INSTALL:: Setting up pacman for mbp packages..."
touch /mnt/etc/pacman.conf
echo "[mbp]" >> /mnt/etc/pacman.conf
echo "Server = https://dl.t2linux.org/mbp/x86_64" >> /mnt/etc/pacman.conf
echo "IgnorePkg = linux linux-headers" >> /mnt/etc/pacman.conf
pacman -Syy
pacman --noconfirm -S wget
wget http://dl.t2linux.org/archlinux/key.asc
pacman-key --add key.asc
pacman-key --finger 7F9B8FC29F78B339
pacman-key --lsign-key 7F9B8FC29F78B339
rm key.asc

# pacstrap
pacstrap /mnt linux-mbp linux-mbp-headers linux-firmware base base-devel grub-efi-x86_64 zsh zsh-completions vim nano strace git efibootmgr dialog wpa_supplicant man-db

# TODO test everything past here!

# chroot, set up root, user account, hfsprogs, esp
arch-chroot /mnt /bin/bash << "EOT"

echo "root:$ROOT_PASSWORD" | chpasswd
useradd -m -g users -G wheel,storage,power -s /bin/zsh $USERNAME
echo "$USERNAME:$USR_PASSWORD" | chpasswd
echo "${USERNAME} ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers
su $USERNAME -c git clone https://aur.archlinux.org/hfsprogs.git && cd hfsplus && makepkg -si
mkfs.hfsplus -v "$ESP_NAME" $ESP_DEVICE
su $USERNAME -c git clone https://aur.archlinux.org/aic94xx-firmware.git && cd aic94xx-firmware && makepkg -si
su $USERNAME -c git clone https://aur.archlinux.org/wd719x-firmware.git && cd wd719x-firmware && makepkg -si
su $USERNAME -c git clone https://aur.archlinux.org/upd72020x-fw.git && cd upd72020x-fw && makepkg -si

EOT

# mount esp and genfstab
mount /dev/nvme0n1p3 /mnt/boot
genfstab -pU /mnt >> /mnt/etc/fstab

# chroot for basic config
arch-chroot /mnt /bin/bash << "EOT"

# set time
ln -sf /usr/share/zoneinfo/$REGION/$CITY /etc/localtime
hwclock --systohc

# set hostname/network stuff
echo $HOST_NAME >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1 localhost" >> /etc/hosts
echo "127.0.1.1 ${HOST_NAME}" >> /etc/hosts

# set locale
echo LANG=en_US.UTF-8 >> /etc/locale.conf
echo LANGUAGE=en_US >> /etc/locale.conf
echo LC_ALL=C >> /etc/locale.conf
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen

# pacman again
pacman --noconfirm -S linux-mbp linux-mbp-headers linux-firmware intel-ucode

# set up chosen bootloader on esp
if [$BOOTMANAGER == 0]
then
    declare -x SYSTEMD_RELAX_ESP_CHECKS=1
    declare -x SYSTEMD_RELAX_XBOOTLDR_CHECKS=1
    bootctl --path=/boot --no-variables install
    systemctl mask systemd-boot-system-token.service
elif [$BOOTMANAGER == 1]
then
    touch /boot/mach_kernel
    mkdir -p /boot/EFI/BOOT && touch /boot/EFI/BOOT/mach_kernel
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --removable
    grub-mkconfig -o /boot/grub/grub.cfg
    mv /boot/efi/BOOT/System /boot/
    rm -r /boot/efi
    sed -i 's/<plist version="1.0">/<?xml version="1.0" encoding="UTF-8"?>\n<plist version="1.0">' /boot/System/Library/CoreServices/SystemVersion.plist
    sed -i 's/grub/Linux/' /boot/System/Library/CoreServices/SystemVersion.plist
    sed -i 's/2.04/Arch Linux/' /boot/System/Library/CoreServices/SystemVersion.plist
fi

# get nice icon for boot menu
pacstrap -S librsvg libicns
wget -O /tmp/archlinux.svg https://archlinux.org/logos/archlinux-icon-crystal-64.svg
rsvg-convert -w 128 -h 128 -o /tmp/archlogo.png /tmp/archlinux.svg
png2icns /boot/.VolumeIcon.icns /tmp/archlogo.png
rm /tmp/archlogo.png /tmp/archlinux.svg

# all done, exit everything now
sync

EOT

sync
echo "reboot when ready..."
exit 0
