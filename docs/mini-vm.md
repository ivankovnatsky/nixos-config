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

## Network Limitations

Mini-vm runs in OrbStack's NAT network (198.19.249.x) which provides isolation but has limitations for hardware-specific services.

**See [docs/mini.md](./mini.md#orbstack-vm-network-limitations)** for detailed network limitations including link-local address access and service migration considerations.

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

Services on mini-vm are accessible via the hostname `mini-vm.orb.local`, which automatically resolves to the correct IP even after Orbstack restarts. No manual IP updates are needed.

**Important**: The `.orb.local` hostname is only resolvable from the Mac mini (OrbStack host). For services accessed from other machines (like bee), the Caddy configuration must:

1. Forward from bee to Mac mini IP (192.168.50.4)
2. Mac mini then forwards to `mini-vm.orb.local`

This two-hop forwarding is handled automatically by the shared Caddy templates - bee forwards to mini, mini forwards to the VM.
