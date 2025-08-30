{
  imports = [
    ../../modules/nixos/tmux-rebuild
    ./configuration.nix
    # ./open-webui.nix  # Temporarily disabled - chromadb package is broken
    ./tmux-rebuild.nix
    ./packages.nix
  ];
}
