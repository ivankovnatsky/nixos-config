# Steam Deck NixOS Setup

```console
passwd ivan
```

Follow [nixos-install-luks.md](nixos-install-luks.md) for disk setup. Used 16GB
for swap:

```console
lvcreate -L 16G -n swap vg
```

WIFI is 192.168.50.10, ethernet is 192.168.50.11.

```console
ssh-copy-id ivan@192.168.50.103
```

## Initial WiFi Connection

Connect via command line:

```console
nmcli device wifi connect "SSID" --ask
```

**Note:** Steam Deck doesn't have working Ethernet, so WiFi is required.
Ethernet worked via Satechi hub during install.

Make sure to go over the configuration.nix and enable network manager, user,
ssh, open ports for syncthing.

(After reboot)

## Packages

```console
sudo nix-env -iA \
  nixos.syncthing \
  nixos.vim \
  nixos.tmux
```

## Syncthing

```console
ssh ivan@192.168.50.11 'tmux new -d -s syncthing "syncthing -gui-address=0.0.0.0:8384"'
```

Device and folder sharing is handled by `syncthing-mgmt.nix`. Update the
steamdeck device ID in sops secrets (`syncthing/devices`) after reinstall.

Grab the device ID from steamdeck:

```console
ssh ivan@192.168.50.11 'grep -oP "<apikey>\K[^<]+" ~/.local/state/syncthing/config.xml'
```

Then update sops:

```console
sops secrets/default.yaml
```

## Copy hardware and base configuration

Copy hardware configuration from live system:

```console
scp ivan@192.168.50.11:/etc/nixos/hardware-configuration.nix machines/steamdeck/nixos/
scp ivan@192.168.50.11:/etc/nixos/configuration.nix machines/steamdeck/nixos/
```

nixos-config is synced via Syncthing from other machines.

Then on steamdeck:

```console
cd ~/Sources/github.com/ivankovnatsky/nixos-config
sudo nixos-rebuild switch --flake .#steamdeck
```

## TPM2

### Enrolling TPM2 (if available)

The Steam Deck system uses a single LUKS-encrypted partition that contains both
root and swap. You only need to enroll TPM2 for this single encrypted partition:

```console
sudo systemd-cryptenroll --tpm2-device=auto /dev/disk/by-uuid/2dc67f0b-3182-4780-90de-a8e8ca94e370
```

After enrolling TPM2, enable the `cryptenroll.nix` module in
`machines/steamdeck/nixos/default.nix` to automatically unlock during boot
without requiring a passphrase.

## SSH Key Setup

Set up SSH key access to a3 for remote building:

```console
ssh-copy-id a3
```

This allows steamdeck to use a3 as a remote build host without password prompts.

## Rebuild

```console
sudo nixos-rebuild switch --flake .#steamdeck
```

## After another reboot

When asked on Monitor setup, choosen to disable built-in when plugged-in,
replicate that in code?

## Switching to Steam Gaming Mode

Log out, select "SteamOS (gamescope)" at SDDM login screen. Don't run
`start-gamescope-session` from within KDE.
