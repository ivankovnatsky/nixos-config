{
  # Desktop session management
  # Comment/uncomment the session you want to use

  imports = [
    # Desktop environments
    ./plasma.nix # KDE Plasma 6 (currently active)
    ./kde.nix

    # ./gnome.nix      # GNOME (available but commented)

    # Minimal window managers (for virtual console startup)
    # ../../nixos/dwm        # Sophisticated dwm with patches
    # ../../nixos/dwm-vanilla  # Vanilla dwm for testing
  ];
}
