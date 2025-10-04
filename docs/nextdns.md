# NextDNS

This will load environment variables from `.envrc`, including:
- `NEXTDNS_API_KEY` - API key for NextDNS management

The `.envrc` file is encrypted with git-crypt, so you'll need access to the repository's git-crypt key.

## API Reference

NextDNS API documentation: https://nextdns.github.io/api/

### Verify

## Tools

### NextDNS Management

The `nextdns-mgmt` tool is available after home-manager rebuild:

```console
# Export a profile
nextdns-mgmt --api-key $NEXTDNS_API_KEY export --profile-id <profile-id> --format json

# List all profiles
nextdns-mgmt --api-key $NEXTDNS_API_KEY export --list-profiles

# Sync profile from local JSON
nextdns-mgmt --api-key $NEXTDNS_API_KEY sync --profile-id <profile-id> --profile-file machines/bee/nextdns/profile.json --dry-run
```
