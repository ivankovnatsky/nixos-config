{
  imports = [
    # ./gnome.nix
    ../../modules/nixos/tmux-rebuild
    ../../system/nix.nix
    ../../nixos/chromium.nix
    ./bluetooth.nix
    ./boot.nix
    ./configuration.nix
    ./cryptenroll.nix # TPM2 support for LUKS encryption
    ./fonts.nix

    # ./gamemode.nix
    # ./gamescope.nix
    ./xserver.nix
    ./kde.nix

    ./nixpkgs.nix
    ./nvidia.nix
    ./power-management.nix
    ./security.nix
    ./steam.nix
    ./sudo.nix
    ./tmux-rebuild.nix
    ./tpm2.nix
    ./user.nix
  ];
}
