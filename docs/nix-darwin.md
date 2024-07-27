# nix-darwin

Install nix using determinate system:

(Probably a good idea to check for the latest release)

```console
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Install syncthing to fetch local network copy of nixos-config:

```console
nix-env -iA nixpkgs.syncthing
```

Follow instructions here:

<https://github.com/LnL7/nix-darwin>

```console
nix run nix-darwin -- switch --flake ".#Ivans-MacBook-Pro"
sudo mv /etc/nix/nix.conf /etc/nix/nix.conf.before-nix-darwin
sudo mv /etc/zshenv /etc/zshenv.before-nix-darwin
```

Install git-crypt before running switch:

```console
nix-env -iA nixpkgs.git-crypt
```

then:

```console
nix --extra-experimental-features nix-command --extra-experimental-features flakes run nix-darwin -- switch  --flake ".#Ivans-MacBook-Pro"
```
