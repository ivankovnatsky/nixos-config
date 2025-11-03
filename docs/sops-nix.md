# SOPS-Nix Secret Management

## Adding a new age key

Example of adding a new machine's age key to `.sops.yaml`:

```yaml
keys:
  - &home 6BD3724830BD941E9180C1A33A33FA4C82ED674F
  - &mini age1nxsvvlxhutf7kr26ucc60r48lge779dducnknyr9pceej52nqgnqlvqe25
  - &new_machine age1hs5w7sk6lll4szvpqjf5uz5pvfl...  # Add new age public key here

creation_rules:
  - path_regex: secrets/.*\.yaml$
    key_groups:
    - pgp:
      - *home
      age:
      - *mini
      - *new_machine  # Reference it here
```

## Re-encrypt secrets after key changes

After updating `.sops.yaml` (adding/removing keys) or when sops-nix auto-discovers a new SSH host key during rebuild, re-encrypt the secrets file:

```console
sops updatekeys secrets/default.yaml
```

## macOS/Darwin setup

### Full Disk Access requirement

On macOS, `sops-install-secrets` requires **Full Disk Access** permission to read the SSH host key at `/etc/ssh/ssh_host_ed25519_key`.

To grant Full Disk Access:

1. Open **System Settings** → **Privacy & Security** → **Full Disk Access**
2. Click the **+** button
3. Navigate to `/nix/store/` and find the `sops-install-secrets` binary
4. Or add `/bin/sh` (which runs the launchd service)

After granting access, restart the service:

```console
sudo launchctl kickstart -k system/org.nixos.sops-install-secrets
```

Verify secrets were created:

```console
ls -la /run/secrets/
```

### Troubleshooting

If secrets fail to deploy:

- Check service status: `launchctl print system/org.nixos.sops-install-secrets`
- Verify Full Disk Access is granted in System Settings
- Check the service ran successfully (exit code 0)
- Secrets are stored in `/run/secrets.d/1/` and symlinked to `/run/secrets/`
