{
  imports = [
    ../../modules/flags
    ../../modules/secrets
    ../../modules/nixos/tmux-rebuild
    ./networking.nix
    ./configuration.nix
    ./tmux-rebuild.nix
    ./packages.nix
    ./jellyfin.nix
    # ./stash.nix
    ./stash-container.nix
  ];
}
