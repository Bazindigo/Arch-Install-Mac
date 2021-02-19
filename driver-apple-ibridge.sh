# chrooted env
rm -rf /usr/src/apple-ibridge-0.1
git clone --branch mbp15 https://github.com/roadrunner2/macbook12-spi-driver.git /usr/src/apple-ibridge-0.1
dkms install --no-depmod -m apple-ibridge -v 0.1 -k $MBP_KERNEL
depmod $MBP_KERNEL
modprobe -S $MBP_KERNEL -f apple-ib-tb
modprobe -S $MBP_KERNEL -f apple-ib-als
