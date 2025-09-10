# nix-darwin

Install nix using determinate system:

(Probably a good idea to check for the latest release)

```console
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
  | sh -s -- install
```

Run syncthing to fetch local network copy of nixos-config:

```console
nix run "https://flakehub.com/f/NixOS/nixpkgs/*#syncthing"
```

Configure your new machine if needed:

(This avoids installing Apple's git)

```console
nix develop "https://flakehub.com/f/NixOS/nixpkgs/*#git"
```

Run this if needed to tackle with git-crypt:

```console
/nix/store/1y3m89x5sl3bwag9lk4fdbqmswzjp9is-git-2.44.1/bin/git -c \
  filter.git-crypt.clean=cat add .
```

Check instructions here:

<https://github.com/nix-darwin/nix-darwin>

Finally:

```console
nix --extra-experimental-features nix-command --extra-experimental-features \
  flakes run nix-darwin -- switch  --flake ".#Ivans-MacBook-Pro"
sudo mv /etc/nix/nix.conf /etc/nix/nix.conf.before-nix-darwin
sudo mv /etc/zshenv /etc/zshenv.before-nix-darwin
nix --extra-experimental-features nix-command --extra-experimental-features \
  flakes run nix-darwin -- switch  --flake ".#Ivans-MacBook-Pro"
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
