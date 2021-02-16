declare ROOT_PASSWORD = "password0"
declare USERNAME = "user"
declare USR_PASSWORD = "password1"
declare HOST_NAME = "host name"
declare PARTITION_NAME = "Arch Linux"
declare PARTITION_DEVICE = "/dev/nvme0n1p4"
declare ESP_NAME = "Arch Boot"
declare ESP_DEVICE = "/dev/nvme0n1p3"
declare REGION = "America"
declare CITY = "Denver"

mkfs.ext4 -L $PARTITION_NAME /dev/partition_label
mkdir -p /mnt/boot
mount $PARTITION_DEVICE /mnt
pacman -S wget
wget http://dl.t.t2linux.org/archlinux/key.asc
pacman-key --add key.asc
pacman-key --finger 7F9B8FC29F78B339
pacman-key --lsign-key 7F9B8FC29F78B339
rm key.asc
pacstrap /mnt linux-mbp linux-mbp-headers linux-firmware base base-devel grub-efi-x86_64 zsh zsh-completions vim nano strace git efibootmgr dialog wpa_supplicant

arch-chroot /mnt /bin/bash << "EOT"

echo $ROOT_PASSWORD | passwd --stdin
useradd -m -g users -G wheel,storage,power -s /bin/zsh $USERNAME
echo $USR_PASSWORD | passwd MYUSERNAME --stdin
echo "${USERNAME} ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers
su $USERNAME -c git clone https://aur.archlinux.org/hfsprogs.git && cd hfsplus && makepkg -si && mkfs.hfsplus -v $ESP_NAME $ESP_DEVICE && exit

EOT

mount /dev/nvme0n1p3 /mnt/boot
genfstab -pU /mnt >> /mnt/etc/fstab

arch-chroot /mnt /bin/bash << "EOT"

ln -sf /usr/share/zoneinfo/$REGION/$CITY /etc/localtime
hwclock --systohc

echo $HOST_NAME >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1 localhost" >> /etc/hosts
echo "127.0.1.1 ${HOST_NAME}" >> /etc/hosts

echo LANG=en_US.UTF-8 >> /etc/locale.conf
echo LANGUAGE=en_US >> /etc/locale.conf
echo LC_ALL=C >> /etc/locale.conf
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen

pacman -S linux-mbp linux-mbp-headers linux-firmware intel-ucode

declare -x SYSTEMD_RELAX_ESP_CHECKS=1
declare -x SYSTEMD_RELAX_XBOOTLDR_CHECKS=1
bootctl --path=/boot --no-variables install
systemctl mask systemd-boot-system-token.service

sync

EOT

sync
echo "reboot when ready..."
