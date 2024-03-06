# nix-darwin

Install nix unstable:

(Probably a good idea to check for the latest release)

```console
sh <(curl -L https://github.com/nix-community/nix-unstable-installer/releases/download/nix-2.21.0pre20240214_d857914/install)
```

Follow instructions here:

<https://github.com/LnL7/nix-darwin>

```console
nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
./result/bin/darwin-installer
```

brew:

```console
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
/opt/homebrew/bin/brew analytics off
```

Initially you would have to run: `darwin-rebuild switch` that would read ~/.nixpkgs/darwin-configuration.nix

Enable nixFlakes:

```console
cat >> /etc/nix/nix.conf << EOF
experimental-features = nix-command flakes
EOF
```

Install git-crypt before running switch:

```console
nix-env -iA nixpkgs.git-crypt
```

then: `darwin-rebuild switch --flake .#Ivans-MacBook-Air`

If nix installer can't create a `/nix` mountpoint by itself, create it manually:

```
sudo diskutil apfs addVolume disk1 APFS Nix Store -mountpoint /nix
```

Clean stable nix:

```
nix doctor

nix-env -e nix
```
