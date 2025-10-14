{
  # Desktop environment home-manager configuration for a3 machine
  # Comment/uncomment the session you want to use

  imports = [
    # Desktop environments
    # ./plasma.nix # KDE Plasma config
    # ./kwinoutput # KDE window output config

    ./gnome.nix # GNOME config

    # Minimal window managers
    # (dwm typically doesn't need home-manager config)
  ];
}
