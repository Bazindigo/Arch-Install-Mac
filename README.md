# Installing Arch Linux on a Macbook Pro 2019
* requirements:
  * a partition set up for your linux installation
  * a separate partition for to use as your mac's second EFI partition

## Steps
1. `pacman -Syy && pacman -S git`
2. `git clone https://github.com/Bazindigo/Arch-Install-Mac.git`
3. edit script variables:
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
4. `./install_arch.sh`
