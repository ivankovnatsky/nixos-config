# utm-vm

## Steps

```console
sudo nix-env -iA nixos.vim
sudo vim /etc/nixos/configuration.nix
```

- Add vim
- Tmux
- Syncthing
- Enable firewall for ssh and syncthing
- Start syncthing in tmux
- Add VM syncthing ID
- Share nixos-config repo with syncthing

```console
mv /etc/nixos/* ~/Sources/github.com/ivankovnatsky/nixos-config/machines/utm-nixos/
cd ~/Sources/github.com/ivankovnatsky/nixos-config/machines/utm-nixos/
cat << EOF > default.nix
{
  imports = [
    ./configuration.nix
  ];
}
EOF
```

- Add machine to flake

```console
cd ~/Sources/github.com/ivankovnatsky/nixos-config/
sudo nixos-rebuild switch --flake .#utm-nixos
```

- Remove hostname from configuration.nix
- Add clean up other not needed items:
  - xserver block
