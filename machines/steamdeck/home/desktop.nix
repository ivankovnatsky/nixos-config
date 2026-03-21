{
  # Desktop environment home-manager configuration
  # Comment/uncomment the session you want to use

  imports = [
    # Desktop environments
    ../../../home/nixos/plasma.nix # KDE Plasma config
    ./kwinoutput # KDE window output config
    ./plasma.nix # Steamdeck-specific Plasma overrides

    # ../../../home/gnome.nix # GNOME config

    # Minimal window managers
    # (dwm typically doesn't need home-manager config)
  ];
}
