{
  imports = [
    ../../modules/flags
    ../../modules/secrets
    ../../modules/nixos/tmux-rebuild-poll
    ../../modules/nixos/audiobookshelf-mgmt
    ./networking.nix
    ./configuration.nix
    ./tmux-rebuild-poll.nix
    ./packages.nix
    ./jellyfin.nix
    ./server
  ];
}
