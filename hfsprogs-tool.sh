# chrooted env
cd /home/$USERNAME
rm -rf hfsprogs
git clone https://aur.archlinux.org/hfsprogs.git
cd hfsprogs
makepkg -si --noconfirm
rm -rf hfsprogs