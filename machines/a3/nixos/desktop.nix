{
  # Desktop session management
  # Comment/uncomment the session you want to use

  imports = [
    # Desktop environments
    ./kde.nix
    ./plasma.nix # KDE Plasma 6 (currently active)

    # ./gnome.nix      # GNOME (available but commented)

    # Minimal window managers (for virtual console startup)
    # ../../nixos/dwm        # Sophisticated dwm with patches
    # ../../nixos/dwm-vanilla  # Vanilla dwm for testing
  ];
}
