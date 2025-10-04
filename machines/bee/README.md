# Bee Homelab Server

## Configure

### SSH

```console
ssh-copy-id bee-ip
```

## Services

### DNS Server

The machine is configured to run local DNS server using dnsmasq. We resolve all
of the zone to single IP, it's either `bee`'s or `mini`'s IP, configured to be
static in router DHCP settings.

> Note: We use `.lan` instead of `.local` because macOS reserves the `.local`
> top-level domain for Multicast DNS (mDNS/Bonjour). Using `.local` domains can
> cause resolution issues on macOS systems as they intercept these requests and
> try to resolve them via mDNS instead of regular DNS.

We don't use local, lan or homelab anymore for a local zone.

### Logging Stack

The server uses the following components for log collection and visualization:

- **Grafana**: Web interface for visualizing logs and metrics (https://grafana.{externalDomain})
- **Loki**: Log aggregation system that stores and indexes logs
- **Promtail**: Agent that collects logs from the system and forwards them to Loki

Default Grafana credentials:

- Username: admin
- Password: admin (change on first login)

## TODO

- [ ] Add availability dashboard
- [ ] Can we somehow security automatically always apply rebuild only with some
      specific user and specific command
- [x] Grafana
  - [ ] System metrics
