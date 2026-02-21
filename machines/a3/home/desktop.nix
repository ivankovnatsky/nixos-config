{
  # Desktop environment home-manager configuration
  # Comment/uncomment the session you want to use

  imports = [
    # Desktop environments
    ./kwinoutput # KDE window output config
    ../../../home/nixos/plasma.nix # KDE Plasma config

    # ../../../home/gnome.nix # GNOME config

    # Minimal window managers
    # (dwm typically doesn't need home-manager config)
  ];
}
