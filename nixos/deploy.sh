#!/usr/bin/env bash

set -ex

# ripped off from here: https://gist.github.com/walkermalling/23cf138432aee9d36cf59ff5b63a2a58

lsblk --fs

# or nvme0n1
wipefs -a /dev/sda

parted /dev/sda:

mklabel gpt
mkpart ESP fat32 1MiB 512MiB
set 1 boot on
mkpart primary 512MiB 100%

cryptsetup luksFormat /dev/sda2
cryptsetup luksOpen /dev/sda2 crypted

pvcreate /dev/mapper/crypted
vgcreate vg /dev/mapper/crypted

# or 32G
lvcreate -L 8G -n swap vg
lvcreate -l '100%FREE' -n root vg

mkfs.fat -F 32 -n boot /dev/sda1
mkfs.ext4 -L root /dev/vg/root
mkswap -L swap /dev/vg/swap

mount /dev/disk/by-label/root /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
swapon /dev/disk/by-label/swap

# nmcli dev wifi connect SSID password SSID_PASS
tee /etc/wpa_supplicant.conf << EOF
network={
        ssid="{{ SSID }}"
        psk="{{ PASSWORD }}"
        scan_ssid=1
}
EOF

systemctl restart wpa_supplicant.service

# or you graphical interface

# check internet/dns
ping duckduckgo.com

nixos-generate-config --root /mnt

nix-env -iA nixos.git
nix-env -iA nixos.neovim
git clone https://git.sr.ht/~sevenfourk/dotfiles /mnt/home/ivan
git clone https://git.sr.ht/~sevenfourk/nix-configs /mnt/home/ivan/Sources/SourceHut/nix-configs

ln -sf /mnt/home/ivan/SourceHut/nix-configs/nixos/configuration/mac.nix /mnt/etc/nixos/configuration.nix

nix-channel --add https://github.com/NixOS/nixos-hardware/archive/master.tar.gz nixos-hardware
nix-channel --update

# to check linking
vim /mnt/etc/nixos/configuration.nix
nixos-install

chown -Rv ivan:users /mnt/home/ivan

reboot

# home-manager
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install

ln -sf /home/ivan/SourceHut/nix-configs/nixos/home/home.nix /home/ivan/.config/nixpkgs/home.nix

# configure autorandr
arandr # -- configure laptop only
autorandr --save mobile

arandr # -- add monitor
autorandr --save docked
