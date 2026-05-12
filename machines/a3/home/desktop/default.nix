{ ... }:

{
  # Desktop environment home-manager configuration.

  imports = [
    ../../../../home/nixos/plasma.nix # KDE Plasma config

    ./kwinoutput # KDE window output config

    ./btop.nix
    ./firefox.nix
    ./flags.nix
    ./gpg.nix
    ./obsidian.nix
    ./packages.nix
    ./tools.nix
  ];
}
