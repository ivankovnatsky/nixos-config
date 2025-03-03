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
