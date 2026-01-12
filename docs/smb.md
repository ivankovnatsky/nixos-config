# SMB Password Management

This document describes how to configure and manage SMB/CIFS shares for storage
access between machines.

## Overview

The a3 machine mounts SMB shares from mini machine using macOS built-in File
Sharing:

- **macOS File Sharing**: Standard SMB port 445
- **Security**: Uses dedicated sharing-only user `samba` (separate from system
  user `ivan`)
- **User Management**: Manually configured in System Settings
- **File ownership**: All files owned by user `ivan`

## Configuration

**Mini machine** - Manual user setup required:

1. Create sharing-only user via System Settings → Users & Groups:
   - Username: `samba`
   - Password: (from `modules/secrets/default.nix -> secrets.smb.mini.password`)
   - Shell: `/bin/zsh`
   - Home: `/Users/samba`

2. Enable File Sharing in System Settings → General → Sharing:
   - Turn on "File Sharing"
   - Click (i) button → Add folder: `/Volumes/Storage/Data`
   - Share name: `Storage`
   - Add user `samba` with Read & Write permissions

**A3 machine** mounts the share configured in `machines/a3/smb.nix`:

- Mount point: `/mnt/smb/mini-storage`
- Share: `//ivans-mac-mini.local/Storage`
- Standard SMB port: 445
- Credentials: Stored in Nix store (referenced from
  `modules/secrets/default.nix`)
- SMB username: `samba` (separate from system user `ivan`)

## Notes

- The `samba` user is a sharing-only user managed manually in System Settings
