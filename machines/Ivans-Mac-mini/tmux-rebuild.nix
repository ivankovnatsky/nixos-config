{
  imports = [
    ../../modules/darwin/tmux-rebuild
  ];

  # FIXME: Prepend local for all local modules
  services.tmuxRebuild.nixosConfigPath = "/Volumes/Samsung2TB/Sources/github.com/ivankovnatsky/nixos-config";
}
