# Beelink Homelab Server

## Services

### DNS Server

The machine is configured as a local DNS server using dnsmasq. It resolves the following domains:

- `sync.beelink.home.local` → 192.168.50.169
- `beelink.home.local` → 192.168.50.169

## TODO

- [x] Configure DNS server
- [x] Configure service http routing for sync.beelink.home.local -> 192.168.50.169:8384
