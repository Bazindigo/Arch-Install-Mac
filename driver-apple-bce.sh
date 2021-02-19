# chrooted env
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
