{
  imports = [
    ../../modules/secrets
    ../../modules/flags

    ../../modules/nixos/tmux-rebuild
    ../../system/nix.nix
    ../../nixos/chromium.nix
    ./bluetooth.nix
    ./boot.nix
    ./configuration.nix
    ./default-apps.nix
    ./cryptenroll.nix # TPM2 support for LUKS encryption
    ./fonts.nix

    # ./gamemode.nix
    # ./gamescope.nix
    ./desktop.nix

    ./networking.nix
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
