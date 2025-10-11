{
  imports = [
    ../../modules/flags
    ../../modules/secrets
    ../../modules/nixos/tmux-rebuild-poll
    ./networking.nix
    ./configuration.nix
    ./tmux-rebuild-poll.nix
  ];
}
