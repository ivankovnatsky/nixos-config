# beelink

## Installation

Installation was done using mostly graphical UI, disk setup as well. Used schema:

1. EFI partition
2. /boot
3. /
4. swap

## Transfer Configuration Using magic-wormhole

### On Source Machine (MacOS)

```console
# Create a tarball of the configuration
cd /Users/Ivan.Kovnatskyi/Sources/github.com/ivankovnatsky/
tar -czf nixos-config.tar.gz nixos-config

# Send the tarball using magic-wormhole
wormhole send nixos-config.tar.gz
# Note the code provided by wormhole (e.g., 7-crossword-giraffe)
```

### On Beelink (Target Machine)

```console
# Install magic-wormhole
sudo nix-env -iA nixos.magic-wormhole

# Receive the tarball
wormhole receive [code-from-source]
# Enter the code provided by the source machine

# Create directory structure and extract
mkdir -p ~/Sources/github.com/ivankovnatsky
mv nixos-config.tar.gz ~/Sources/github.com/ivankovnatsky/
tar -xzf nixos-config.tar.gz
mv ~/Sources/github.com/ivankovnatsky/nixos-config ~/Sources/github.com/ivankovnatsky/nixos-config-beelink

# Enable flakes for this session (we'll configure it permanently in NixOS later)
export NIX_CONFIG="experimental-features = nix-command flakes"

# Build and switch using the extracted configuration
cd nixos-config-beelink
sudo nixos-rebuild switch --flake .#beelink
```

## Configuration

### Disk encryption enrollment

The beelink configuration uses LUKS encryption for the root partition. To enhance security and convenience, you can use `systemd-cryptenroll` to add additional authentication methods such as TPM2 or recovery keys.

#### Prerequisites

1. First, apply the base NixOS configuration which includes TPM2 support:

```console
sudo nixos-rebuild switch --flake .#beelink
```

2. Once the base configuration with TPM2 support is applied, you can proceed to enrolling authentication methods using systemd-cryptenroll.

#### Enrolling TPM2 (if available)

You need to enroll TPM2 for both LUKS devices (root and swap partitions). Note that while you have two encrypted partitions, NixOS is configured to use the same passphrase for both when unlocking manually, which is why you only get prompted once during boot:

```console
# Enroll TPM2 for root partition
sudo systemd-cryptenroll --tpm2-device=auto /dev/disk/by-uuid/d60d88b5-b111-42bc-a377-dd4cc5630f0f

# Enroll TPM2 for swap partition
sudo systemd-cryptenroll --tpm2-device=auto /dev/disk/by-uuid/14c9a632-e607-49b2-ac01-965dbe30d02e
```

#### Adding a recovery key (optional)

You can add a recovery key as an additional backup authentication method in case the TPM2 becomes unavailable or fails. This is completely optional, as your original passphrase will always remain valid and can be used to decrypt your partitions regardless of whether you add a recovery key or not.

You can add recovery keys for both partitions:

```console
# Add recovery key for root partition
sudo systemd-cryptenroll --recovery-key /dev/disk/by-uuid/d60d88b5-b111-42bc-a377-dd4cc5630f0f

# Add recovery key for swap partition (optional)
sudo systemd-cryptenroll --recovery-key /dev/disk/by-uuid/14c9a632-e607-49b2-ac01-965dbe30d02e
```

This will generate a new recovery key (typically a long string of characters) that will be displayed in the terminal. You should write down this key and store it securely (e.g., in a password manager or a physical safe). The key is stored in the LUKS header of your encrypted disk as an additional authentication method alongside your original passphrase.

When booting, if TPM2 authentication fails, you'll be prompted to enter either:

1. Your original passphrase that you used during initial LUKS encryption setup, OR
2. The recovery key (if you added one)

Your original passphrase always remains valid, even if you add TPM2 authentication or recovery keys. Adding new authentication methods does not invalidate existing ones. No additional configuration is needed in the NixOS configuration to use any of these methods.

### Configuration Options

To make the enrolled authentication methods work with NixOS, the necessary configuration has been added to a dedicated file:

```
machines/beelink/cryptenroll.nix
```

This file contains the required LUKS configuration with TPM2 support. It includes:

- LUKS configuration with TPM2 device auto-detection for both root and swap partitions
- Detailed comments about the correct order of operations

Note that the TPM2 support (`security.tpm2.enable = true`) is already enabled in the `default.nix` file, so it will be available before you enroll the TPM2 authentication.

#### Multiple Encrypted Partitions

When using TPM2 authentication with multiple encrypted partitions (root and swap):

1. **Manual Unlocking**: Without TPM2, NixOS is configured to use the same passphrase for both partitions, which is why you only get prompted once during boot.

2. **Automatic Unlocking**: With TPM2 properly enrolled, both partitions will be unlocked automatically without any passphrase prompt.

3. **Fallback Behavior**: If TPM2 authentication fails, you'll be prompted for the passphrase once, and NixOS will use it to unlock both partitions.

#### Un-enrollment

If you need to remove an authentication method from a LUKS device, you can use the `systemd-cryptenroll` command with the `--wipe-slot` option. First, list the enrolled authentication methods to identify the slot you want to remove:

```console
# List enrolled authentication methods for root partition
sudo systemd-cryptenroll /dev/disk/by-uuid/d60d88b5-b111-42bc-a377-dd4cc5630f0f --list-enrolled

# List enrolled authentication methods for swap partition
sudo systemd-cryptenroll /dev/disk/by-uuid/14c9a632-e607-49b2-ac01-965dbe30d02e --list-enrolled
```

This will show you the available slots and their types (password, recovery key, TPM2, etc.). Then, you can remove a specific authentication method:

```console
# Remove TPM2 from root partition
sudo systemd-cryptenroll /dev/disk/by-uuid/d60d88b5-b111-42bc-a377-dd4cc5630f0f --wipe-slot=tpm2

# Remove recovery key from root partition
sudo systemd-cryptenroll /dev/disk/by-uuid/d60d88b5-b111-42bc-a377-dd4cc5630f0f --wipe-slot=recovery

# Remove a specific password slot (replace N with the slot number)
sudo systemd-cryptenroll /dev/disk/by-uuid/d60d88b5-b111-42bc-a377-dd4cc5630f0f --wipe-slot=N
```

**Important**: Always ensure you have at least one working authentication method remaining after un-enrollment. Otherwise, you might lose access to your encrypted data.

#### Troubleshooting

If you encounter issues with authentication methods:

- For TPM2, verify that your system has a TPM2 module and it's enabled in BIOS/UEFI
- You can list enrolled authentication methods with: `sudo systemd-cryptenroll /dev/disk/by-uuid/d60d88b5-b111-42bc-a377-dd4cc5630f0f --list-enrolled`

## Media Server Setup

### Overview

The media server setup consists of four main components working together:

1. **Radarr**: Manages movie downloads and library organization
   - Monitors for new movies
   - Sends download requests to Transmission
   - Manages movie files after download
   - API Key found in Settings -> General

2. **Prowlarr**: Indexer management
   - Manages and proxies requests to torrent trackers
   - Integrates with Radarr via API
   - Supports multiple trackers (e.g., Toloka.to)

3. **Transmission**: Download client
   - Handles torrent downloads
   - Downloads to `/media/downloads/movies`
   - Configured without authentication for local network access

4. **Plex**: Media streaming server
   - Serves media files for streaming
   - Manages movie metadata and library
   - Accessible at `http://plex.beelink.homelab` or `http://192.168.50.169:32400/web`

### Directory Structure

```
/media/
├── downloads/
│   └── movies/     # Temporary download location
└── movies/         # Final movie library location
```

### Initial Setup

1. **Prowlarr Setup**:
   - Access at `http://prowlarr.beelink.homelab`
   - Add indexers (e.g., Toloka.to):
     - Go to Settings -> Indexers
     - Click '+' to add new indexer
     - Configure indexer settings (URL, credentials)
   - Connect to Radarr:
     - Go to Settings -> Apps
     - Add Radarr application
     - Use Radarr's API key from Settings -> General
     - Set Radarr URL: `http://localhost:7878`

2. **Radarr Setup**:
   - Access at `http://radarr.beelink.homelab`
   - Add Transmission as download client:
     - Settings -> Download Clients
     - Add Transmission
     - Host: `localhost`
     - Port: `9091`
   - Configure movie paths:
     - Download path: `/media/downloads/movies`
     - Library path: `/media/movies`

3. **Transmission Setup**:
   - Access at `http://transmission.beelink.homelab`
   - Downloads automatically go to configured paths
   - No authentication required on local network

4. **Plex Setup**:
   - Initial setup: Access via `http://192.168.50.169:32400/web`
   - Add Movies library:
     - Click '+' next to Libraries
     - Choose 'Movies' type
     - Add folder: `/media/movies`
     - Configure scanning options as needed
   - After initial setup, can use `http://plex.beelink.homelab`

### Workflow

1. Add a movie in Radarr
2. Radarr finds the movie and sends it to Transmission
3. Transmission downloads to `/media/downloads/movies`
4. Radarr moves completed download to `/media/movies`
5. Plex detects new movie and adds it to library

### Troubleshooting

- If Plex shows "Get Media Server" screen:
  - Access via direct IP: `http://192.168.50.169:32400/web`
  - Use incognito/private browser window
  - Clear browser cookies for Plex domain

## BIOS

Optimized fan settings to be:

Fan off temperature limit: 30 -> 70°C
Fan start temperature limit: 35 -> 80°C

## References

- [balint's nixos-configs](https://codeberg.org/balint/nixos-configs) - Contains advanced TPM2 PCR configuration examples
