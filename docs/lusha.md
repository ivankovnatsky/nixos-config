# Lusha work machine

## Google Calendar Sync

Enabled Google Calendar sync with Apple Calendar app via:
https://calendar.google.com/calendar/u/0/syncselect

Selected all needed calendars to display in the Apple Calendar app.

## Atlassian MCP Authentication

After adding Atlassian MCP server with `--user` scope, authenticated by running:

```console
claude /mcp
```

Pressed `1` twice to trigger OAuth flow - browser opened automatically for authentication.

## Remote Login

Configured SSH remote login for my user account only via System Settings.

Allows terminal access for remote administration and troubleshooting from other devices on the network or via Tailscale VPN.

## Screen Sharing

Configured screen sharing via System Settings with the following options:

- **Allow access for**: Only my user
- **VNC viewers may control screen with password**: Enabled
- **Anyone may request permission to control screen**: Enabled

Enables remote desktop access via VNC/Apple Remote Desktop for system maintenance and troubleshooting.

## App macOS settings

### Zoom

- Approve local network access

### Kitty

- Open app from the internet -- Allow
