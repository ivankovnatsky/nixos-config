# nix-darwin

Install nix using determinate system:

(Probably a good idea to check for the latest release)

```console
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Run syncthing to fetch local network copy of nixos-config:

```console
nix run "https://flakehub.com/f/NixOS/nixpkgs/*#syncthing"
```

Configure your new machine if any:

(This avoids installing Apple's git)

```console
nix develop "https://flakehub.com/f/NixOS/nixpkgs/*#git"
/nix/store/1y3m89x5sl3bwag9lk4fdbqmswzjp9is-git-2.44.1/bin/git -c filter.git-crypt.clean=cat add .
```

Check instructions here:

<https://github.com/LnL7/nix-darwin>

Finally:

```console
nix --extra-experimental-features nix-command --extra-experimental-features flakes run nix-darwin -- switch  --flake ".#Ivans-MacBook-Pro"
sudo mv /etc/nix/nix.conf /etc/nix/nix.conf.before-nix-darwin
sudo mv /etc/zshenv /etc/zshenv.before-nix-darwin
nix --extra-experimental-features nix-command --extra-experimental-features flakes run nix-darwin -- switch  --flake ".#Ivans-MacBook-Pro"
```
