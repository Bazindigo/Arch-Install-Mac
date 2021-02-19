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
pacstrap /mnt linux-mbp linux-mbp-headers linux-firmware base base-devel dkms grub-efi-x86_64 zsh zsh-completions vim nano strace git efibootmgr dialog wpa_supplicant man-db wget librsvg libicns perl intel-ucode

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
#mkinitcpio -p linux-mbp -k $MBP_KERNEL # try without generating here for now in interest of efficiency

# set up chosen bootloader on esp
echo ""
echo "===> ARCH_INSTALL:: (10/12) Installing bootloader..."
if [ $BOOTMANAGER==0 ];then
    echo "===> ARCH_INSTALL::     Using systemd"
    ./systemd_install.sh
elif [ $BOOTMANAGER==1 ];then
    echo "===> ARCH_INSTALL::     Using GRUB"
    ./grub_install.sh
fi

# get nice icon for boot menu
echo ""
echo "===> ARCH_INSTALL:: (11/12) Grabbing icon for Apple boot menu..."
./boot_icon.sh

# t2/keyboard/touchpad
echo ""
echo "===> ARCH_INSTALL:: (12/12) Installing additional drivers..."
./driver-apple-ibridge.sh
./driver-apple-bce.sh
./config-mkinitcpio.sh
pacman --noconfirm -Syy linux-mbp linux-mbp-headers
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
