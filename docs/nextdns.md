# NextDNS

The NextDNS API key is now managed through sops-nix for secure secret management.

## API Reference

NextDNS API documentation: https://nextdns.github.io/api/

## Automated Profile Management

Launchd jobs are configured to automatically sync NextDNS profiles on system startup:

- **mini**: Two profiles (mini, asus)
- **pro**: Four profiles (pro, air, phone, asus)

The jobs run at system startup and apply the configuration from `configs/nextdns-profile.json`.

## Manual CLI Usage

### Quick Examples

```bash
# Update pro profile (dry-run)
API_KEY=$(sops -d --extract '["nextDnsApiKey"]' secrets/secrets.yaml) \
PROFILE_ID=$(sops -d --extract '["nextDnsProfilePro"]' secrets/secrets.yaml) \
nextdns-mgmt update --api-key "$API_KEY" --profile-id "$PROFILE_ID" \
  --profile-file configs/nextdns-profile.json --dry-run
```

### Ad-Hoc Usage Without Rebuild

If you don't want to add the package to home packages, use this one-liner:

```bash
# One-liner to update a specific profile (no rebuild needed)
API_KEY=$(sops -d --extract '["nextDnsApiKey"]' secrets/secrets.yaml) \
PROFILE_ID=$(sops -d --extract '["nextDnsProfilePro"]' secrets/secrets.yaml) \
$(nix-build --no-out-link -E 'with import <nixpkgs> {}; callPackage ./packages/nextdns-mgmt/default.nix {}')/bin/nextdns-mgmt \
  update --api-key "$API_KEY" --profile-id "$PROFILE_ID" --profile-file configs/nextdns-profile.json --dry-run
```
