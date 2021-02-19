# chrooted env
sed -i 's/MODULES=()/MODULES=(bce apple-ibridge apple-ib-tb apple-ib-als)/' /etc/mkinitcpio.conf
echo "blacklist thunderbolt" >> /etc/modprobe.d/local-blacklist.conf           # blacklist thunderbolt module directly
echo "install thunderbolt /bin/false" >> /etc/modprobe.d/local-blacklist.conf  # run /bin/false when thunderbolt is attempting to load
