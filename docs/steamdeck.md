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

Share nixos-config and Sources folders from a3 using curl commands:

On a3, set up environment variables (get steamdeck's device ID from its
Syncthing UI: Actions > Show ID):

```console
export API_KEY=$(grep -oP '<apikey>\K[^<]+' ~/.local/state/syncthing/config.xml)
export A3_HOST='127.0.0.1:8384'
export STEAMDECK_DEVICE_ID="YOUR_STEAMDECK_DEVICE_ID"
```

Add steamdeck as a device on a3:

```console
curl -X POST -H "X-API-Key: $API_KEY" -H "Content-Type: application/json" -d "{\"deviceID\":\"$STEAMDECK_DEVICE_ID\",\"name\":\"steamdeck\"}" http://$A3_HOST/rest/config/devices
```

Add nixos-config folder and share it with steamdeck:

```console
curl -X PUT -H "X-API-Key: $API_KEY" -H "Content-Type: application/json" -d "{\"id\":\"shtdy-s2c9s\",\"label\":\"nixos-config\",\"path\":\"~/Sources/github.com/ivankovnatsky/nixos-config\",\"devices\":[{\"deviceID\":\"$STEAMDECK_DEVICE_ID\"}]}" http://$A3_HOST/rest/config/folders/shtdy-s2c9s
```

Share Sources folder with steamdeck (update existing folder to add steamdeck
device):

```console
curl -X PATCH -H "X-API-Key: $API_KEY" -H "Content-Type: application/json" -d "{\"devices\":[{\"deviceID\":\"$STEAMDECK_DEVICE_ID\"}]}" http://$A3_HOST/rest/config/folders/fpbxa-6zw5z
```

Note: This PATCH will add steamdeck while preserving other devices that
Syncthing automatically includes.

Trigger folder scans:

```console
curl --max-time 5 -X POST -H "X-API-Key: $API_KEY" http://$A3_HOST/rest/db/scan?folder=shtdy-s2c9s
curl --max-time 5 -X POST -H "X-API-Key: $API_KEY" http://$A3_HOST/rest/db/scan?folder=fpbxa-6zw5z
```

## Copy hardware and base configuration

Copy hardware configuration from live system:

```console
cp /etc/nixos/.* machines/steamdeck/nixos/
```

## TPM2

### Enrolling TPM2 (if available)

The Steam Deck system uses a single LUKS-encrypted partition that contains both
root and swap. You only need to enroll TPM2 for this single encrypted partition:

```console
sudo systemd-cryptenroll --tpm2-device=auto /dev/disk/by-uuid/2b9052dc-f819-4ff3-98e6-661a45a2cc3e
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
