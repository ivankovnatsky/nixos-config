# macOS

Related to macOS various configuration and tweaks.

## TCC (Transparency, Consent, and Control)

### Check Full Disk Access Permissions

Query the TCC database to see which applications and binaries have Full Disk Access:

```bash
sudo sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" "SELECT service, client, client_type, auth_value, auth_reason FROM access WHERE service = 'kTCCServiceSystemPolicyAllFiles';"
```

The output shows:
- `client`: Application bundle ID (type 0) or file path (type 1)
- `client_type`: 0 = app bundle, 1 = absolute path
- `auth_value`: 0 = denied, 2 = allowed
- `auth_reason`: Reason for authorization (4 = user-set, 5 = system-set)

Note: System binaries in `/bin`, `/usr/bin` with the `restricted` flag (SIP-protected) cannot be granted Full Disk Access. Use `ls -lO /path/to/binary` to check for the `restricted` flag.

## System Settings

- Enable `Use the Caps Lock key to switch to and from ABC`
- Enable `Automatically switch to a document's input source`

## Safari

### Keyboard Shortcuts

#### Re-bind Close Window and Quit Safari

- <https://apple.stackexchange.com/questions/209295/stop-safari-window-closing-when-only-pinned-tabs-are-left>
- <https://i.imgur.com/cZgKdss.jpg>

#### Change keybinding for "Move focus to next window or next window

`` Option + ` `` (Scope of single desktop)
