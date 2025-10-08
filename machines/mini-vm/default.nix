{
  imports = [
    ../../modules/flags
    ../../modules/secrets
    ../../modules/nixos/tmux-rebuild
    ../../modules/nixos/audiobookshelf-mgmt
    ./networking.nix
    ./configuration.nix
    ./tmux-rebuild.nix
    ./packages.nix
    ./jellyfin.nix
    ./server
  ];
}
