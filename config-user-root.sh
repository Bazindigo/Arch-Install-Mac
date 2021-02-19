# chrooted env
echo root:${ROOT_PASSWORD} | chpasswd

useradd -m -g users -G wheel,storage,power -s /bin/zsh -p $(perl -e 'print crypt($ARGV[0], "password")' '$USR_PASSWORD') $USERNAME

echo "$USERNAME ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers
