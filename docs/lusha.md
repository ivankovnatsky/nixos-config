# Lusha work machine

## Calendar

Do not add work calendars to Apple Calendar - Google Calendar sync can be slow
to update and unreliable for time-sensitive work events.

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

Configured Do Not Disturb to filter out Iru MDM notifications:

1. Open System Settings → Focus → **Do Not Disturb**
2. Configure:
   - **Silenced Apps**: Add "Iru Menu"
   - **Schedule**: 00:00, every day (always on)

## Keyboard

### Shortcuts

#### Mission Control

Enable switch to Desktop 1-16 shortcuts:

1. Open System Settings → Keyboard → Keyboard Shortcuts → Mission Control
2. Enable "Switch to Desktop 1" through "Switch to Desktop 16"

Toggle these shortcuts off and back on to make cmux Ctrl+1 focus default
shortcuts work.

## App macOS settings

## bash

- Allow "bash" to control "System Events"
- Allow "bash" to control "Terminal"

### Zoom

- Approve local network access

### Kitty

- Open app from the internet -- Allow
- Notifications
- Local network access
- Allow access to control "Google Chrome"

### Hammerspoon

- Allow access to control "System Events" (required for space management via
  osascript)

### Ghostty

- Approve local network access

### container (Apple container runtime)

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
    - Turn off Daily Schedules
  - Configure email forwarding to personal Slack channel to avoid opening
    gmail.com for emails

### LinearMouse

- Accessibility permissions granted
- Configured reverse scrolling direction (natural scrolling for mouse)
- No smooth scrolling feature (downgrade from Mos which had this)

### Mac Mouse Fix

- Enable Mac Mouse Fix: on
- Grant Accessibility Access
- Show in Menu Bar: on
- Check for Updates: off

### Chromium

- Allow:
  - Camera
  - Microphone

### Google Chrome

- Allow:
  - Local network (find devices on local networks)
- Plugins:
  - Dark Reader
  - Okta Browser Plugin

### Cloudflare WARP

- Allow:
  - Notifications

### Weather

- Allow:
  - Location ("Weather" would like to use your current location)
- Menu Bar: Show in Menu Bar (enabled)

### Raycast

- Allow access to control "System Events"

### Firefox

- Allow:
  - Camera
  - Microphone

### cmux

- Allow:
  - Notifications
  - Local network
