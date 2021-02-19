# Installing Arch Linux on a Macbook Pro 2019
## Requirements
* one partition for your linux installation
  * already partitioned from macOS or using a disk utility in the arch iso
* one partition for your new EFI (different than the EFI partition already on your mac)
  * again, already partitioned from macOS or using a disk utility in arch iso
* an Arch Linux installation USB
  * if the ISO used was the regular ISO, then you will have to add the following group to `/etc/pacman.conf`:
    ```
    [mbp]
    Server = https://packages.aunali1.com/archlinux/$repo/$arch
    ```
    * you also need to add `linux` and `linux-headers` to the `IgnorePkg` list earlier in the same file

## Steps
1. Boot into arch iso from a USB
2. `pacman -Syy && pacman -S git glibc`
3. `git clone https://github.com/Bazindigo/Arch-Install-Mac.git`
4. edit script variables in the first few lines of `install-arch.sh`:
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
5. If you want to install with systemd: `./install-arch.sh systemd`. 
    * If you want to install with GRUB: `./install-arch.sh grub`
    * If you run it without any arguments, it will default to systemd.
6. After any finishing touches on your install, `reboot` and hold option on startup. Select the new option in the menu.
  * If this doesn't work, you may have to use the bless command from macOS and then try booting into it
