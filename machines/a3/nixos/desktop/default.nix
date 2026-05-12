{
  imports = [
    ./kde.nix
    ./plasma.nix
    # ./gnome.nix

    ./bluetooth.nix
    ./fwupd.nix
    ./nvidia.nix
    # ./openrgb.nix
    ./wifi.nix

    ./default-apps.nix
    ./fonts.nix

    ./gamescope.nix
    # ./gamemode.nix
    ./steam.nix

    ./boot.nix
    ./cryptenroll.nix
    ./power-management.nix
    ./tpm2.nix
    ./user.nix
  ];
}
