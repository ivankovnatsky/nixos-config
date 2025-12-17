# nix-darwin

Install nix using determinate system:

(Probably a good idea to check for the latest release)

```console
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
  | sh -s -- install

. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

Run syncthing to fetch local network copy of nixos-config:

```console
nix run "https://flakehub.com/f/NixOS/nixpkgs/*#syncthing"
```

Share dirs:

- nixos-config
- gnupg

Install Developer tools, they still needed for brew to work normally, run any
git command for that.

Configure your new machine if needed:

(This avoids installing Apple's git)

```console
nix develop "https://flakehub.com/f/NixOS/nixpkgs/*#git"
```


Check instructions here:

<https://github.com/nix-darwin/nix-darwin>

Install rosetta:

```console
softwareupdate --install-rosetta
```

Enable Remote Login (SSH) to generate host keys for sops-nix:

```console
sudo systemsetup -setremotelogin on
```

SSH from another machine to trigger host key generation:

```console
ssh <hostname>.local
```

If sops secrets were encrypted with old machine's SSH host keys (e.g., after macOS
reinstall), re-encrypt with the new host key:

```console
nix shell nixpkgs#ssh-to-age -c ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
```

Update `.sops.yaml` with the new age key, then re-encrypt:

```console
nix shell nixpkgs#sops nixpkgs#gnupg
gpg --list-secret-keys
sops updatekeys secrets/default.yaml
```

Finally:

```console
sudo nix --extra-experimental-features nix-command --extra-experimental-features \
  flakes run nix-darwin -- switch  --flake ".#Ivans-MacBook-Pro"
sudo mv /etc/nix/nix.conf /etc/nix/nix.conf.before-nix-darwin
sudo mv /etc/zshenv /etc/zshenv.before-nix-darwin
sudo nix --extra-experimental-features nix-command --extra-experimental-features \
  flakes run nix-darwin -- switch  --flake ".#Ivans-MacBook-Pro"
```

Install Claude Code for help:

```console
nix shell nixpkgs#nodejs
npm install -g @anthropic-ai/claude-codeo
~/.npm/bin/claude
```

## Homebrew Package Management

### How Homebrew Updates Work with nix-darwin

1. **Flake updates** control the available package versions (the "catalog")
2. **`onActivation.upgrade`** controls whether to actually upgrade installed packages
3. **`greedy`** flag needed for auto-updating casks

### Upgrading Homebrew Packages

By default, Homebrew skips auto-updating casks during `brew upgrade`. This includes:

- Casks with `version :latest`
- Casks marked with `auto_updates` flag (like `ghostty@tip`)

To upgrade these casks, you need to:

1. Set `onActivation.upgrade = true` in your homebrew configuration
2. For auto-updating casks, use the `greedy` flag:
   ```nix
   casks = [
     { name = "ghostty@tip"; greedy = true; }
   ];
   ```

### Update Workflow

1. Update homebrew flakes to get latest package definitions:

   ```console
   make flake-update-homebrew
   ```

2. Rebuild darwin configuration to apply updates:
   ```console
   darwin-rebuild switch --flake .
   ```

### References

- [Why aren't some apps included during brew upgrade?](https://docs.brew.sh/FAQ#why-arent-some-apps-included-during-brew-upgrade)
