# gpg

## Troubleshooting

### No pinentry

When trying to sign a commit, the following error is shown:

```console
at Jan 15 20:19 ❯ git c overlays/ghostty/default.nix
error: gpg failed to sign the data:
[GNUPG:] KEY_CONSIDERED 6BD3724830BD941E9180C1A33A33FA4C82ED674F 2
[GNUPG:] BEGIN_SIGNING H8
gpg: signing failed: No pinentry
[GNUPG:] FAILURE sign 67108949
gpg: signing failed: No pinentry

fatal: failed to write commit object
nixos-config on  main [$!+] took 12s
```

To fix this:

```console
gpgconf --kill gpg-agent
```
