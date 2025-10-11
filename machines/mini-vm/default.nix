{
  imports = [
    ../../modules/flags
    ../../modules/secrets
    ../../modules/nixos/tmux-rebuild-poll
    ./configuration.nix
    ./tmux-rebuild-poll.nix
  ];
}
