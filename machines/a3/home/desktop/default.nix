{ ... }:

{
  # Desktop environment home-manager configuration.

  imports = [
    ./kwinoutput # KDE window output config

    ./btop.nix
    ./firefox.nix
    ./flags.nix
    ./gpg.nix
    ./obsidian.nix
    ./packages.nix
    ./plasma.nix
    ./tools.nix
  ];
}
