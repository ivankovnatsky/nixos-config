# nix-darwin

Install nix stable:

```
<(curl -L https://nixos.org/nix/install) --darwin-use-unencrypted-nix-store-volume
```

Or unstable:

```
sh <(curl -L https://github.com/numtide/nix-unstable-installer/releases/download/nix-2.9.0pre20220428_660835d/install)
```

Follow instructions here:

<https://github.com/LnL7/nix-darwin>

```
nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
./result/bin/darwin-installer
```

brew:

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew analytics off
```

Initially you would have to run: `darwin-rebuild switch` that would read ~/.nixpkgs/darwin-configuration.nix

Enable nixFlakes:

```
cat >> /etc/nix/nix.conf << EOF
experimental-features = nix-command flakes
EOF
```

then: `darwin-rebuild switch --flake .`

If nix installer can't create a `/nix` mountpoint by itself, create it manually:

```
sudo diskutil apfs addVolume disk1 APFS Nix Store -mountpoint /nix
```

Fix zsh permissions:

```
compaudit | xargs chmod g-w,o-w
```

Keep sudo session a little bit longer:

```
sudo bash -c 'cat << EOF > /etc/sudoers.d/default
Defaults timestamp_timeout=240
EOF'
```

Clean stable nix:

```
nix doctor

nix-env -e nix
```
