# SMB Password Management

This document describes how to change SMB/CIFS passwords for shared storage access between machines.

## Overview

The a3 machine mounts SMB shares from:

- **bee machine**: Linux Samba share at `//bee/storage`

## Changing Passwords

### Bee Machine (Linux/Samba)

To change the SMB password for the `ivan` user on the bee machine:

```console
# Change Samba password for user ivan
sudo smbpasswd ivan
```

You'll be prompted to enter the new password twice.

### Test SMB Connection

```console
# Test connection to bee share
smbclient -L //bee -A /etc/nixos/smb-credentials-bee
```
