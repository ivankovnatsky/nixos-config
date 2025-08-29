# Nix Cache Server Setup

## Overview

The bee machine runs a local Nix binary cache server using `nix-serve`. This provides faster builds and reduced bandwidth usage for other machines in the network.

## Server Configuration

### On the bee machine:

1. The cache server is configured in `machines/bee/nix-serve.nix`
2. Accessible via `https://cache.${externalDomain}` (proxied through Caddy)
3. Signing key is automatically generated on first run

### Public Key

The cache server's public key is:
```
bee:/9R3r9DsSErFv0A1yBIzgaF1XCcF7XmKJBSrPE+axp0=
```

## Client Configuration

### Darwin machines (with Determinate Nix)

Since nix-darwin is disabled, manually add to `/etc/nix/nix.custom.conf`:

```
extra-trusted-substituters = https://cache.${externalDomain}
extra-trusted-public-keys = bee:/9R3r9DsSErFv0A1yBIzgaF1XCcF7XmKJBSrPE+axp0=
```

Then restart the Nix daemon:
```console
sudo launchctl kickstart -k system/org.nixos.nix-daemon
```

### NixOS machines (a3)

The configuration is already set up in `machines/a3/nix-cache.nix`. To enable:

1. Add to imports in `machines/a3/default.nix`:
   ```nix
   ./nix-cache.nix
   ```
2. Rebuild the system

## Usage

Once configured, Nix will automatically:
1. Check the local cache first for binary packages
2. Fall back to official caches if not found locally
3. Populate the local cache when building packages

## Testing

Verify cache is working:

```console
# Test cache accessibility
curl -I https://cache.${externalDomain}

# Check if a package is cached (example with hello)
curl https://cache.${externalDomain}/nix-cache-info

# Monitor cache usage
nix store ping --store https://cache.${externalDomain}
```
