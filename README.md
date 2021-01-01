# nix-configs

## Installation

### Check UUID and wipe the disk

```console
lsblk --fs
wipefs -a /dev/nvme0n1
```

### Partition the disk

```console
parted /dev/nvme0n1

mklabel gpt
mkpart ESP fat32 1MiB 512MiB
set 1 boot on
mkpart primary 512MiB 100%
```

### Encrypt disk

```console
cryptsetup luksFormat /dev/nvme0n1p2
cryptsetup luksOpen /dev/nvme0n1p2 crypted

pvcreate /dev/mapper/crypted
vgcreate vg /dev/mapper/crypted

lvcreate -L 32G -n swap vg
lvcreate -l '100%FREE' -n root vg
```

### Format disk

```console
mkfs.fat -F 32 -n boot /dev/nvme0n1p1
mkfs.ext4 -L root /dev/vg/root
mkswap -L swap /dev/vg/swap

mount /dev/disk/by-label/root /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
swapon /dev/disk/by-label/swap
```

### Connect to internet

```console
nmcli dev wifi connect SSID password SSID_PASS
ping duckduckgo.com
```

### Install NixOS

As `home-manager`, `nixos-hardware` included in the config, we might not need
to install channels explicitly, but this had not been tested yet.

```console
nixos-generate-config --root /mnt

nix-env -iA nixos.git
nix-env -iA nixos.neovim

git clone https://git.sr.ht/~ikovnatsky/nix-configs /mnt/home/ivan/Sources/Home/SourceHut/nix-configs
ln -sf /mnt/home/ivan/Sources/Home/SourceHut/nix-configs/system/configuration.nix /mnt/etc/nixos/configuration.nix

nvim /mnt/etc/nixos/configuration.nix

nixos-install

chown -R ivan:users /mnt/home/ivan

reboot
```

## Reference

<https://gist.github.com/walkermalling/23cf138432aee9d36cf59ff5b63a2a58>
