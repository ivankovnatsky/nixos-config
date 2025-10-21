{
  # Enable KDE Partition Manager with proper D-Bus access
  # https://github.com/NixOS/nixpkgs/issues/273659#issuecomment-1852402674
  programs.partition-manager.enable = true;
}
