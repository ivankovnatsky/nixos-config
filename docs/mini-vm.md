# mini-vm

## Overview

`mini-vm` is a NixOS virtual machine running on Orbstack on Mac mini used for development and testing.

## Creation

The mini-vm was created manually through the Orbstack UI.

To create a NixOS VM via command line, you would use:

```console
orb create nixos:25.05 mini-vm
```

Note: After creation, the VM's configuration is managed entirely through NixOS flakes.

## Manual

- General
  - Start at login
- Storage
  - Set to /Volumes/Storage/Data/OrbStack
- Kubernetes
  - Enabled (manually configured through UI)

## Network Configuration

The VM uses Orbstack's networking with:
- IP Address: `198.19.249.245` (automatically assigned by Orbstack)

## Services

Currently no active services. OpenWebUI was disabled due to chromadb package being broken on ARM64.

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
