# Beelink Homelab Server

## Configure

### SSH

```console
ssh-copy-id 192.168.50.169
```

## Services

### DNS Server

The machine is configured as a local DNS server using dnsmasq. It resolves the following domains:

- `sync.beelink.home.lan` → 192.168.50.169
- `beelink.home.lan` → 192.168.50.169

> Note: We use `.lan` instead of `.local` because macOS reserves the `.local` top-level domain for Multicast DNS (mDNS/Bonjour). Using `.local` domains can cause resolution issues on macOS systems as they intercept these requests and try to resolve them via mDNS instead of regular DNS.

## TODO

- [x] Configure DNS server
- [x] Configure service http routing for sync.beelink.home.lan -> 192.168.50.169:8384
