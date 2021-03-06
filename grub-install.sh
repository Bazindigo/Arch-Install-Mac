# use from chrooted env
#sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="TODO SOMETHING WAS HERE"/GRUB_CMDLINE_LINUX_DEFAULT="rootflags=data-writeback libata.force=noncq"/' /etc/default/grub
touch /boot/mach_kernel
mkdir -p /boot/EFI/BOOT && touch /boot/EFI/BOOT/mach_kernel
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --removable
grub-mkconfig -o /boot/grub/grub.cfg
mv /boot/efi/BOOT/System /boot/
grub-mkstandalone -o /boot/System/Library/CoreServices/boot.efi -d /usr/lib/grub/x86_64-efi -O x86_64-efi /boot/grub/grub.cfg
rm -r /boot/efi
sed -i 's/<plist version="1.0">/<?xml version="1.0" encoding="UTF-8"?>\n<plist version="1.0">' /boot/System/Library/CoreServices/SystemVersion.plist
sed -i 's/grub/Linux/' /boot/System/Library/CoreServices/SystemVersion.plist
sed -i 's/2.04/Arch Linux/' /boot/System/Library/CoreServices/SystemVersion.plist
