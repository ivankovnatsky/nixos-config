# mini-vm

## Overview

`mini-vm` is a NixOS virtual machine running on Orbstack on Mac mini. It provides services like Open WebUI for the homelab infrastructure.

## Manual

- General
  - Start at login
- Storage
  - Set to /Volumes/Storage/Data/OrbStack

## Network Configuration

The VM uses Orbstack's networking with:
- IP Address: `198.19.249.245` (automatically assigned by Orbstack)

## Services

## Management

To access the VM:

```console
ssh ivan@mini-vm@orb
```

To list all VMs:

```console
orb list
```

To rebuild NixOS configuration:

```console
sudo nixos-rebuild switch --flake .
```

## Troubleshooting

If the IP address changes after Orbstack restart:
1. Check current IP: `orb list`
2. Update `miniVmIp` in `modules/flags/default.nix`
3. Rebuild configurations on bee and Mac mini
