#!/bin/bash
# edit the following variables
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

# leave these ones alone
declare BOOTMANAGER=$1
declare MBP_KERNEL="5.8.17-1-mbp"

add_pacman_key () {
    wget https://packages.aunali1.com/archlinux/key.asc
    pacman-key --add key.asc
    pacman-key --finger 7F9B8FC29F78B339
    pacman-key --lsign-key 7F9B8FC29F78B339
    rm key.asc
}

# set bootmanager flag
if [ "$BOOTMANAGER" = "systemd" ];then
    declare BOOTMANAGER=0
elif [ "$BOOTMANAGER" = "grub" ];then
    declare BOOTMANAGER=1
else
    echo "===> ARCH_INSTALL:: Bootloader not specified; defaulting to systemd";
    declare BOOTMANAGER=0
fi

# export variables so they are accessible inside chrooted env
echo ""
echo "===> ARCH_INSTALL:: (1/12) Exporting variables to chroot environment..."
export USERNAME=$USERNAME
export ROOT_PASSWORD=$ROOT_PASSWORD
export USR_PASSWORD=$USR_PASSWORD
export ESP_NAME=$ESP_NAME
export ESP_DEVICE=$ESP_DEVICE
export HOST_NAME=$HOST_NAME
export MBP_KERNEL=$MBP_KERNEL
export -f add_pacman_key

# format the main partition and mount it
echo ""
echo "===> ARCH_INSTALL:: (2/12) Unmounting, formatting, and remounting ${PARTITION_DEVICE}..."
umount -q $ESP_DEVICE # just in case part 1
umount -q $PARTITION_DEVICE # just in case part 2
mkfs.ext4 -q -L "$PARTITION_NAME" $PARTITION_DEVICE
mkdir -p /mnt/boot
mount $PARTITION_DEVICE /mnt

# pacstrap
echo ""
echo "===> ARCH_INSTALL:: (3/12) Installing..."
add_pacman_key
pacstrap /mnt linux-mbp linux-mbp-headers linux-firmware base base-devel dkms grub-efi-x86_64 zsh zsh-completions vim nano strace git efibootmgr dialog wpa_supplicant man-db wget librsvg libicns perl

# set up pacman on new system too
arch-chroot /mnt /bin/bash << "EOT"

echo "[mbp]" >> /etc/pacman.conf
echo "Server = https://packages.aunali1.com/archlinux/mbp/x86_64" >> /etc/pacman.conf
echo "" >> /etc/pacman.conf
sed -i 's/#IgnorePkg/IgnorePkg = linux linux-headers/' /etc/pacman.conf
add_pacman_key
pacman -Syy

# set up root, user account, hfsprogs, esp
echo ""
echo "===> ARCH_INSTALL:: (4/12) Setting locale..."
echo LANG=en_US.UTF-8 >> /etc/locale.conf
echo LANGUAGE=en_US >> /etc/locale.conf
echo LC_ALL=C >> /etc/locale.conf
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen

echo ""
echo "===> ARCH_INSTALL:: (5/12) Setting up user ${USERNAME}..."

echo root:${ROOT_PASSWORD} | chpasswd

useradd -m -g users -G wheel,storage,power -s /bin/zsh -p $(perl -e 'print crypt($ARGV[0], "password")' '$USR_PASSWORD') $USERNAME

echo "$USERNAME ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers

echo ""
echo "===> ARCH_INSTALL:: (6/12) Unmounting, formatting, and remounting ${ESP_DEVICE}..."
cd /home/$USERNAME

rm -rf hfsprogs
su $USERNAME -c "git clone https://aur.archlinux.org/hfsprogs.git && cd hfsprogs && makepkg -si --noconfirm"
rm -rf hfsprogs

su $USERNAME -c "mkfs.hfsplus -v \"$ESP_NAME\" $ESP_DEVICE"

echo ""
echo "===> ARCH_INSTALL:: (7/12) Installing additional modules..."
rm -rf aic94xx-firmware
rm -rf wd719x-firmware
rm -rf upd72020x-fw
su $USERNAME -c "git clone https://aur.archlinux.org/aic94xx-firmware.git && cd aic94xx-firmware && makepkg -si --noconfirm"
rm -rf aic94xx-firmware
su $USERNAME -c "git clone https://aur.archlinux.org/wd719x-firmware.git && cd wd719x-firmware && makepkg -si --noconfirm"
rm -rf wd719x-firmware
su $USERNAME -c "git clone https://aur.archlinux.org/upd72020x-fw.git && cd upd72020x-fw && makepkg -si --noconfirm"
rm -rf upd72020x-fw

EOT

# mount esp and genfstab
echo ""
echo "===> ARCH_INSTALL:: (8/12) Performing basic configuration..."
mount $ESP_DEVICE /mnt/boot
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

# pacman again
echo ""
echo "===> ARCH_INSTALL:: (9/12) Regenerating images..."
pacman --noconfirm -Sy dkms linux-mbp linux-mbp-headers linux-firmware intel-ucode
#mkinitcpio -p linux-mbp -k $MBP_KERNEL # try without generating here for now in interest of efficiency

# set up chosen bootloader on esp
echo ""
echo "===> ARCH_INSTALL:: (10/12) Installing bootloader..."
if [ $BOOTMANAGER==0 ];then
    echo "===> ARCH_INSTALL::     Using systemd"
    declare -x SYSTEMD_RELAX_ESP_CHECKS=1
    declare -x SYSTEMD_RELAX_XBOOTLDR_CHECKS=1
    bootctl --path=/boot --no-variables install
    systemctl mask systemd-boot-system-token.service
elif [ $BOOTMANAGER==1 ];then
    echo "===> ARCH_INSTALL::     Using GRUB"
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
echo ""
echo "===> ARCH_INSTALL:: (11/12) Grabbing icon for Apple boot menu..."
wget -O /tmp/archlinux.svg https://archlinux.org/logos/archlinux-icon-crystal-64.svg
rsvg-convert -w 128 -h 128 -o /tmp/archlogo.png /tmp/archlinux.svg
png2icns /boot/.VolumeIcon.icns /tmp/archlogo.png
rm /tmp/archlogo.png /tmp/archlinux.svg

# t2/keyboard/touchpad
echo ""
echo "===> ARCH_INSTALL:: (12/12) Installing additional drivers..."
rm -rf /usr/src/apple-ibridge-0.1
git clone --branch mbp15 https://github.com/roadrunner2/macbook12-spi-driver.git /usr/src/apple-ibridge-0.1
dkms install --no-depmod -m apple-ibridge -v 0.1 -k $MBP_KERNEL
depmod $MBP_KERNEL
modprobe -S $MBP_KERNEL -f apple-ib-tb
modprobe -S $MBP_KERNEL -f apple-ib-als

cd /
rm -rf /mbp2018-bridge-drv
git clone https://github.com/MCMrARM/mbp2018-bridge-drv.git
cd mbp2018-bridge-drv
sed -i 's/$(shell uname -r)/$MBP_KERNEL/' Makefile
make
mkdir -p /usr/lib/modules/extramodules-mbp
cp bce.ko -p /usr/lib/modules/extramodules-mbp/bce.ko # don't know if this one works vs the next line
cp bce.ko -p /usr/lib/modules/5.8.17-1-mbp/bce.ko
echo "bce" > /etc/modules-load.d/bce.conf
rm -rf /mbp2018-bridge-drv

sed -i 's/MODULES=()/MODULES=(bce apple-ibridge apple-ib-tb apple-ib-als)/' /etc/mkinitcpio.conf
echo "blacklist thunderbolt" >> /etc/modprobe.d/local-blacklist.conf           # blacklist thunderbolt module directly
echo "install thunderbolt /bin/false" >> /etc/modprobe.d/local-blacklist.conf  # run /bin/false when thunderbolt is attempting to load
mkinitcpio -p linux-mbp -k $MBP_KERNEL

# TODO wifi
# TODO touchbar
# TODO audio
# TODO suspend

# all done, exit everything now
sync

EOT

sync
echo ""
echo "===> ARCH_INSTALL:: Finished"
exit 0
