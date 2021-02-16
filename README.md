# Installing Arch Linux on a Macbook Pro 2019
## Requirements
* Macbook Pro 2019 16"
* one partition for your linux installation
  * already partitioned from macOS or using a disk utility in the arch iso
* one partition for your new EFI (different than the EFI partition already on your mac)
  * again, already partitioned from macOS or using a disk utility in arch iso

## Steps
1. Boot into arch iso from a USB
2. `pacman -Syy && pacman -S git`
3. `git clone https://github.com/Bazindigo/Arch-Install-Mac.git`
4. edit script variables:
    * `ROOT_PASSWORD`: the password for root in your installation
    * `USERNAME`: the username of the user to configure
    * `USR_PASSWORD`: the password of the new user
    * `HOST_NAME`: the... you guessed it... hostname
    * `PARTITION_NAME`: the name you want to give to the main filesystem of your linux installation
    * `PARTITION_DEVICE`: the partition to install linux on (on a mac, usually something like `/dev/nvme0n1pX`)
    * `ESP_NAME`: the name you want to give to the esp partition filesystem
    * `ESP_DEVICE`: the partition to use as the esp (same format as PARTITION_DEVICE)
    * `REGION`: the region you are in
    * `CITY`: the city you are in within the region
5. If you want to install with systemd: `./install_arch.sh systemd`. 
    * If you want to install with GRUB: `./install_arch.sh grub`
6. After any finishing touches on your install, `reboot` and hold option on startup. Select the new option in the menu.
