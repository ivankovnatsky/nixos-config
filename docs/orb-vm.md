# orb-vm

## Prepare

```console
cp /etc/nixos/* /mnt/mac/Users/$USER/Sources/github.com/ivankovnatsky/nixos-config/machines/$HOSTNAME/

sudo nix-env -iA nixos.gnumake
sudo nix-env -iA nixos.tmux
make rebuild-nixos/generic
```

Remove incus.nix file and include from configuration.nix.
