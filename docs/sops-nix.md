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
