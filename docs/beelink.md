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

Since the NixOS configuration has already been applied to the beelink machine, you can directly proceed to enrolling authentication methods using systemd-cryptenroll.

#### Enrolling TPM2 (if available)

```console
sudo systemd-cryptenroll --tpm2-device=auto /dev/disk/by-uuid/d60d88b5-b111-42bc-a377-dd4cc5630f0f
```

#### Adding a recovery key (optional but recommended)

It's a good practice to add a recovery key as a backup authentication method in case the TPM2 becomes unavailable or fails. This recovery key is different from the passphrase you initially used when encrypting the LUKS partition during installation:

```console
sudo systemd-cryptenroll --recovery-key /dev/disk/by-uuid/d60d88b5-b111-42bc-a377-dd4cc5630f0f
```

This will generate a new recovery key (typically a long string of characters) that will be displayed in the terminal. You should write down this key and store it securely (e.g., in a password manager or a physical safe). The key is stored in the LUKS header of your encrypted disk as an additional authentication method alongside your original passphrase.

When booting, if TPM2 authentication fails, you'll be prompted to enter either:

1. Your original passphrase that you used during initial LUKS encryption setup, OR
2. This recovery key

Both authentication methods remain valid and can be used interchangeably to unlock your disk. No additional configuration is needed in the NixOS configuration to use either method.

### Configuration Options

To make the enrolled authentication methods work with NixOS, the necessary configuration has been added to a dedicated file:

```
machines/beelink/cryptenroll.nix
```

This file contains the required LUKS configuration with TPM2 support. It includes:

- TPM2 enablement via `security.tpm2.enable = true`
- LUKS configuration with TPM2 device auto-detection
- Detailed comments about the correct order of operations

### Un-enrollment

TODO:

### Troubleshooting

If you encounter issues with authentication methods:

- For TPM2, verify that your system has a TPM2 module and it's enabled in BIOS/UEFI
- You can list enrolled authentication methods with: `sudo systemd-cryptenroll /dev/disk/by-uuid/d60d88b5-b111-42bc-a377-dd4cc5630f0f --list-enrolled`

## References

- [balint's nixos-configs](https://codeberg.org/balint/nixos-configs) - Contains advanced TPM2 PCR configuration examples
