# Lusha work machine

## Calendar

Do not add work calendars to Apple Calendar - Google Calendar sync can be slow to
update and unreliable for time-sensitive work events.

### Google Calendar Sync

Enabled Google Calendar sync with Apple Calendar app via:
https://calendar.google.com/calendar/u/0/syncselect

Selected all needed calendars to display in the Apple Calendar app.

## Atlassian MCP Authentication

After adding Atlassian MCP server with `--user` scope, authenticated by running:

```console
claude /mcp
```

Pressed `1` twice to trigger OAuth flow - browser opened automatically for
authentication.

## Remote Login

- Configured SSH remote login for my user account only
  - Allow full disk for remote users
- Enable Sceen sharing just in case

To be able to rescue the system from the local network if needed

## Screen Sharing

Configured screen sharing via System Settings with the following options:

- **Allow access for**: Only my user
- **VNC viewers may control screen with password**: Enabled
- **Anyone may request permission to control screen**: Enabled

Enables remote desktop access via VNC/Apple Remote Desktop for system
maintenance and troubleshooting.

## Focus

Used Work Focus to filter out Kandji annoying notifications.

## App macOS settings

## bash

- Allow "bash" to control "System Events"
- Allow "bash" to control "Terminal"

### Zoom

- Approve local network access

### Kitty

- Open app from the internet -- Allow
- Notifications

### Hammerspoon

- Allow access to control "System Events" (required for space management via
  osascript)

### Ghostty

- Approve local network access

### Syncthing

- Allow:
  - Local network (find devices on local networks)

### Slack

- Allow:
  - Local network
- App:
  - Configure Google Calendar plugin
    - Add to starred

### LinearMouse

- Accessibility permissions granted
- Configured reverse scrolling direction (natural scrolling for mouse)
- No smooth scrolling feature (downgrade from Mos which had this)

### Chromium

- Allow:
  - Camera
  - Microphone

### Firefox

- Allow:
  - Camera
  - Microphone
