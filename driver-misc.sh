# chroot env
rm -rf aic94xx-firmware
su $USERNAME -c "git clone https://aur.archlinux.org/aic94xx-firmware.git && cd aic94xx-firmware && makepkg -si --noconfirm"
rm -rf aic94xx-firmware

rm -rf wd719x-firmware
su $USERNAME -c "git clone https://aur.archlinux.org/wd719x-firmware.git && cd wd719x-firmware && makepkg -si --noconfirm"
rm -rf wd719x-firmware

rm -rf upd72020x-fw
su $USERNAME -c "git clone https://aur.archlinux.org/upd72020x-fw.git && cd upd72020x-fw && makepkg -si --noconfirm"
rm -rf upd72020x-fw