# Bee Homelab Server

## Configure

### SSH

```console
ssh-copy-id bee-ip
```

## Services

### DNS Server

The machine is configured as a local DNS server using dnsmasq. It resolves the following domains:

- `sync.bee.homelab` → bee-ip
- `bee.homelab` → beepink-ip
- `grafana.bee.homelab` → beepink-ip

> Note: We use `.lan` instead of `.local` because macOS reserves the `.local` top-level domain for Multicast DNS (mDNS/Bonjour). Using `.local` domains can cause resolution issues on macOS systems as they intercept these requests and try to resolve them via mDNS instead of regular DNS.

### Logging Stack

The server uses the following components for log collection and visualization:

- **Grafana**: Web interface for visualizing logs and metrics (http://grafana.bee.homelab)
- **Loki**: Log aggregation system that stores and indexes logs
- **Promtail**: Agent that collects logs from the system and forwards them to Loki

Default Grafana credentials:
- Username: admin
- Password: admin (change on first login)

## TODO

- [x] Configure DNS server
- [x] Configure service http routing for sync.bee.homelab -> bee-ip:8384
- [ ] Add local https
- [x] Rename local domain: .home.lan -> homelab
- [ ] Move data to external drive when got one
- [ ] Add Home Assistant
- [ ] Add availability dashboard
- [ ] Limit the boot timeout
- [ ] Can we somehow security autoamtically always apply rebuild only with some
      specific user and specific command
- [x] Grafana
  - [x] Logs with Loki and Promtail
  - [ ] System metrics
