# nixos-config

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
quit
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
nmcli dev wifi connect SSID password SSID_PASS hidden yes

# or
cat > /etc/wpa_supplicant.conf << EOF
network={
        ssid=""
        psk="sadf98h239d8hasdf"
        scan_ssid=1
}
EOF

systemctl restart wpa_supplicant.service

ping duckduckgo.com
```

### Install NixOS

#### Install

```console
nixos-generate-config --root /mnt

nix-env -iA nixos.git
nix-env -iA nixos.git-crypt
nix-env -iA nixos.neovim

git clone https://github.com/ivankovnatsky/nixos-config /mnt/home/ivan/Sources/Home/GitHub/nixos-config
ln -sf \
  /mnt/home/ivan/Sources/Home/GitHub/nixos-config/flake.nix /mnt/etc/nixos/flake.nix

cd /mnt/home/ivan/Sources/Home/GitHub/nixos-config
nvim .

nixos-install

nixos-enter --root /mnt

chown -R ivan:users /mnt/home/ivan

reboot
```

## Reference

<https://gist.github.com/walkermalling/23cf138432aee9d36cf59ff5b63a2a58>
