# use from chrooted env
declare -x SYSTEMD_RELAX_ESP_CHECKS=1
declare -x SYSTEMD_RELAX_XBOOTLDR_CHECKS=1
bootctl --path=/boot --no-variables install
systemctl mask systemd-boot-system-token.service
