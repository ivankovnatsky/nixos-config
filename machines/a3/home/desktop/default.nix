{ ... }:

{
  # Desktop environment home-manager configuration.

  imports = [
    ./btop.nix
    ./firefox.nix
    ./flags.nix
    ./gpg.nix
    ./kwinoutput # KDE window output config
    ./obsidian.nix
    ./packages.nix
    ./plasma.nix
    ./steam.nix
    ./tools.nix
  ];
}
