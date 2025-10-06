# Beszel Monitoring Setup

Lightweight server monitoring system replacing Netdata.

## Architecture

- **Hub**: Central dashboard running on bee:8091
- **Agent**: Runs on each monitored system (port 45876)
- **Access**: `https://beszel.<domain>` via Caddy reverse proxy

## Configuration

### Hub Service

Location: `machines/bee/server/beszel.nix`

- Binary: `beszel-hub serve --http '<ip>:8091'`
- Data directory: `/var/lib/beszel-hub`
- Port: 8091 (exposed via Caddy)

### Agent Service (NixOS)

Location: `machines/bee/server/beszel.nix`

- Binary: `beszel-agent`
- Port: 45876
- Environment: `LISTEN=45876`
- Runs as: DynamicUser with docker group

### Agent Service (Darwin)

Location: `machines/Ivans-Mac-mini/darwin/server/beszel.nix`

Module: `modules/darwin/beszel-agent`

- Binary: `beszel-agent`
- Port: 45876
- Runs as: LaunchDaemon (root)
- Logs: `/tmp/log/launchd/beszel-agent.{log,error.log}`

### Secrets

Location: `modules/secrets/default.nix`

- `beszel.hubPublicKey`: SSH public key from hub UI

### Caddy Reverse Proxy

Location: `templates/Caddyfile`

- Host: `beszel.<domain>`
- Upstream: `<bee-ip>:8091`

## Monitored Systems

- **bee** (192.168.50.3): NixOS server with hub and agent
- **mini** (192.168.50.4): Mac mini with Darwin agent

## Setup Steps

1. **Deploy hub** (bee machine)

2. **Access hub UI** at `https://beszel.<domain>`
   - Create admin account
   - Click "Add System"
   - Hub displays SSH public key

3. **Add public key to secrets** in `modules/secrets/default.nix`

4. **Deploy agent** (bee or other machine)

5. **Complete in hub UI**:
   - Name: System name (e.g., `bee`, `mini`)
   - Host: System IP address
   - Click "Add"

6. **Verify connection**: Check that system appears connected in hub UI
