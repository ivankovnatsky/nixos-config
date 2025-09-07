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

Mini-vm runs in OrbStack's NAT network (198.19.249.x) which provides isolation but has limitations for hardware-specific services:

### Link-Local Address Access (169.254.0.0/16)
- **Cannot reach** devices using link-local addresses (like Elgato Key Lights at 169.254.1.144)
- Link-local addresses are not routable by design (RFC 3927)
- Only work within the same network segment/broadcast domain

### Services That Should NOT Be Moved to Mini-VM
- **Homebridge with Elgato plugins** - Needs direct access to 169.254.x.x devices
- **Matter-bridge** - Requires mDNS discovery on physical network
- **IoT device integrations** - Many devices fall back to link-local addressing
- **Hardware coordinators** - Zigbee/Z-Wave need direct USB access

### Alternative Solutions
1. **K8s with hostNetwork: true** - Pods can access physical network directly
2. **Keep on physical machines** - Deploy on bee/mini host with full network access
3. **Docker with --network=host** - Container shares host networking

### Testing Connectivity
```console
# From mini host (should work)
ping 169.254.1.144

# From mini-vm (will fail)
ssh ivan@mini-vm@orb 'ping 169.254.1.144'  # Times out
```

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
