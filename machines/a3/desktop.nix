{ config, lib, pkgs, ... }:

{
  # Desktop session management for a3 machine
  # Comment/uncomment the session you want to use

  imports = [
    # Desktop environments
    # ./plasma.nix       # KDE Plasma 6 (currently active)
    # ./gnome.nix      # GNOME (available but commented)

    # Minimal window managers (for virtual console startup)
    ../../nixos/dwm        # Sophisticated dwm with patches
    # ../../nixos/dwm-vanilla  # Vanilla dwm for testing
  ];
}
