{
  imports = [
    ../../modules/nixos/tmux-rebuild
    ../../nixos/nix-cache.nix
    ./configuration.nix
    # ./open-webui.nix  # Temporarily disabled - chromadb package is broken
    ./tmux-rebuild.nix
    ./packages.nix
  ];
}
