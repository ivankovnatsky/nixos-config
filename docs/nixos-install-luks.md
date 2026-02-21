# nixos-install-luks

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

# Identify RAM size and run this command manually.
# If RAM is huge, we don't need huge swapm 96GB -- 8GB
# lvcreate -L 32G -n swap vg
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

When helper packages installed we can fetch gpg keys by accesing another machine
using ssh or syncthing.

If setting up a new machine adapt or copy generated nixos hardware configs to
cloned repo.

```console
nixos-generate-config --root /mnt
cd /mnt/etc/nixos
vim configuration.nix
# Edit desired options:
# - boot.kernelPackages = pkgs.linuxPackages_latest; -- remove for steamdeck
# - set `luks.devices.crypted`, otherwise won't boot
# - networking.hostName
# - networking.networkmanager.enable = true;
# - time.timeZone = "...";
# - i18n.defaultLocale = "en_US.UTF-8";
# - services.xserver.enable (disabled)
# - services.pipewire (enable, pulse.enable)
# - services.libinput.enable
# - users.users.<name> (isNormalUser, extraGroups, packages)
# - services.openssh.enable = true;
# - networking.firewall.allowedTCPPorts = [ 22000 8384 ];
# - networking.firewall.allowedUDPPorts = [ 22000 21027 ];
```

Before running install make sure you added to configuration.nix:

```nix
  boot = {
    initrd = {
      luks.devices.crypted = {
        device = "/dev/disk/by-uuid/e2e28bab-53df-4636-ad2e-20235d4101b9";
        preLVM = true;
      };
    };
  };
```

```console
nixos-install

# Rescue command if needed
# nixos-enter --root /mnt

reboot
```

## Reference

<https://gist.github.com/walkermalling/23cf138432aee9d36cf59ff5b63a2a58>
