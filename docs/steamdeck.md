# Steam Deck NixOS Setup

## Set Password

```console
passwd ivan
```

## Disk Setup

Follow [nixos-install-luks.md](nixos-install-luks.md) for disk setup. Used 16GB
for swap:

```console
lvcreate -L 16G -n swap vg
```

## Network

WiFi is 192.168.50.10, ethernet is 192.168.50.11.

**Note:** When DHCP had not leased the IP yet, I used:

```console
ssh-copy-id ivan@192.168.50.103
```

## Initial WiFi Connection

Connect via command line:

```console
sudo nmcli device wifi connect "SSID" --ask
```

**Note:** Steam Deck has no built-in Ethernet, but USB Ethernet via a Satechi
hub worked during install.

Make sure to go over the configuration.nix and enable network manager, user,
ssh, open ports for syncthing.

## Copy hardware and base configuration

Copy hardware configuration from live system:

```console
scp ivan@192.168.50.11:/etc/nixos/hardware-configuration.nix machines/steamdeck/nixos/
scp ivan@192.168.50.11:/etc/nixos/configuration.nix machines/steamdeck/nixos/
```

## Packages

Bootstrap packages needed before the first flake rebuild:

```console
sudo nix-env -iA \
  nixos.syncthing \
  nixos.vim \
  nixos.tmux
```

## Syncthing

```console
ssh ivan@192.168.50.11 'tmux new -d -s syncthing "syncthing --gui-address=0.0.0.0:8384"'
```

Device and folder sharing is handled by
`modules/nixos/syncthing-mgmt/default.nix`. Update the steamdeck device ID in
sops secrets (`syncthing/devices`) after reinstall.

Grab the device ID from steamdeck:

```console
ssh ivan@192.168.50.11 'syncthing --device-id'
```

Then update sops:

```console
sops secrets/default.yaml
```

### Trigger folder scan on air

Useful to force a rescan and push nixos-config to steamdeck:

```console
syncthing-mgmt cli scan shtdy-s2c9s
```

nixos-config is synced via Syncthing from other machines. After `syncthing-mgmt`
adds the steamdeck device, you still need to manually accept the steamdeck
device on the Air machine in the Syncthing UI and confirm the nixos-config
folder share. Wait for Syncthing to finish syncing before proceeding.

## First rebuild

```console
cd ~/Sources/github.com/ivankovnatsky/nixos-config
sudo nixos-rebuild switch --flake .#steamdeck
```

## Home-Manager Activation

After the first rebuild, check home-manager activation logs for items that need
manual attention:

```console
journalctl -u home-manager-ivan.service -n 100 --no-pager
```

### GitHub CLI authentication

The `ghAuth` activation script runs `gh auth login --git-protocol https --web`
on first install when `~/.config/gh/hosts.yml` does not exist yet. Complete the
GitHub OAuth flow in a browser when prompted. Subsequent rebuilds skip this
step.

### SSH key and age public key

The `generateSshKey` activation script creates `~/.ssh/id_ed25519` if missing
and prints the corresponding age public key. Copy it for the SOPS key setup
below.

## TPM2

### Enrolling TPM2

The Steam Deck system uses a single LUKS-encrypted partition that contains both
root and swap. You only need to enroll TPM2 for this single encrypted partition.

Find the partition UUID with `blkid` and replace accordingly:

```console
sudo systemd-cryptenroll --tpm2-device=auto /dev/disk/by-uuid/<YOUR-UUID>
```

After enrolling TPM2, enable the `cryptenroll.nix` module in
`machines/steamdeck/nixos/default.nix` to automatically unlock during boot
without requiring a passphrase.

## SSH and SOPS Key Setup

### Get age keys from SSH keys

After install or SSH host key change, update `.sops.yaml` with fresh age keys.

System key (from SSH host key):

```console
ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub
```

User key is generated idempotently by `home/ssh.nix` on home-manager activation.
The age public key is printed in the activation logs:

```console
journalctl -u home-manager-ivan.service | grep "age public key"
```

Update the `&steamdeck` and `&steamdeck-user` entries in `.sops.yaml`, then
re-encrypt:

```console
sops updatekeys secrets/default.yaml
```

### Remote build SSH access

Set up SSH key access to a3 for remote building:

```console
ssh-copy-id a3
```

This allows steamdeck to use a3 as a remote build host without password prompts.

## Rebuild

Steam Deck is not fast enough for automatic rebuilds (`rebuild-diff`,
`rebuild-daemon`). Always rebuild manually:

```console
sudo nixos-rebuild switch --flake .#steamdeck
```

If syncthing fails to start after a rebuild error, start it manually:

```console
systemctl --user start syncthing.service
```

## Monitor Setup

When asked on monitor setup, chosen to disable built-in when plugged-in.

## Gamescope Steam Session

Configured in `machines/steamdeck/nixos/jovian.nix` via Jovian-NixOS:

When `autoStart = true`, Jovian replaces display managers with `greetd` +
`jovian-greeter` that boots directly into gamescope with Steam Deck UI. SDDM is
also disabled via `plasma.nix` (`sddm.enable = !config.jovian.steam.autoStart`).

### Switching between modes

- **Gaming to Desktop**: select "Switch to Desktop" in Steam — stops gamescope,
  greeter starts the session from `desktopSession` (plasma)
- **Desktop to Gaming**: log out from Plasma — greeter defaults back to
  gamescope

### Disabling autoStart

Set `autoStart = false` in `jovian.nix` to disable the jovian greeter. SDDM
re-enables via `plasma.nix`. Steam must then be launched manually or via a
desktop session entry.

### Restarting Steam in gamescope

If Steam gets stuck (e.g. on "calculating time remaining..." update screen),
kill the Steam process — gamescope will respawn it automatically:

```console
ssh ivan@192.168.50.10 'kill $(pgrep -xf "/home/ivan/.local/share/Steam/ubuntu12_32/steam.*")'
```

The `gamescope-session` unit refuses manual restart
(`systemctl --user restart`), so killing the Steam process directly is the way
to go.

## Separate Flake Inputs

The Steam Deck uses its own set of flake inputs (`*-nixos-steamdeck-unstable`)
independent from a3's `*-nixos-unstable` inputs. This way updating inputs for a3
does not trigger a rebuild on the Steam Deck.

To update only Steam Deck inputs:

```console
nix flake update nixpkgs-nixos-steamdeck-unstable
```
