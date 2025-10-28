# Steam Deck NixOS Setup

## Initial WiFi Connection

Connect via command line:

```console
nmcli device wifi connect "SSID" --ask
```

**Note:** Steam Deck doesn't have working Ethernet, so WiFi is required.

Make sure to go over the configuration.nix and enable network manager, user,
ssh, open ports for syncthing.

(After reboot)

## Packages

```console
sudo nix-env -iA nixos.nodejs nixos.syncthing nixos.vim nixos.tmux
```

## Syncthing

```console
tmux new -s steamdeck
syncthing -gui-address="0.0.0.0:8384"
```

Share nixos-config from mini.

## Copy hardware and base configuration

Copy hardware configuration from live system:

```console
cp /etc/nixos/.* machines/steamdeck/nixos/
```

## TPM2

### Enrolling TPM2 (if available)

The Steam Deck system uses a single LUKS-encrypted partition that contains both
root and swap. You only need to enroll TPM2 for this single encrypted
partition:

```console
sudo systemd-cryptenroll --tpm2-device=auto /dev/disk/by-uuid/2b9052dc-f819-4ff3-98e6-661a45a2cc3e
```

After enrolling TPM2, enable the `cryptenroll.nix` module in
`machines/steamdeck/nixos/default.nix` to automatically unlock during boot
without requiring a passphrase.

## Rebuild

```console
cat <<EOF > ~/.npmrc
prefix=~/.npm
EOF
npm install -g @anthropic-ai/claude-code
~/.npm/bin/claude
sudo nixos-rebuild switch --flake .#steamdeck
```

## After another reboot

When asked on Monitor setup, choosen to disable built-in when plugged-in,
replicate that in code?

## Switching to Steam Gaming Mode

Log out, select "SteamOS (gamescope)" at SDDM login screen. Don't run
`start-gamescope-session` from within KDE.
