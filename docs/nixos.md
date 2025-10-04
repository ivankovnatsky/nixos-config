# NixOS Rebuild Errors

## "Could not acquire lock" / "Failed to start transient service unit"

### Fix

```bash
sudo systemctl stop nixos-rebuild-switch-to-configuration.service
```
