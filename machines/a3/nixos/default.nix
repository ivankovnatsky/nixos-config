{
  imports = [
    # ./gamemode.nix
    # ./gamescope.nix
    ./nvidia.nix
    # ./smb.nix
    ../../../modules/flags
    ../../../modules/nixos/tmux-rebuild
    ../../../nixos/chromium.nix
    ../../../system/nix.nix
    ../../../system/scripts
    ./bluetooth.nix
    ./boot.nix
    ./configuration.nix
    ./cryptenroll.nix # TPM2 support for LUKS encryption
    ./default-apps.nix
    ./desktop.nix
    ./fonts.nix
    ./networking.nix
    ./nixpkgs.nix
    ./power-management.nix
    ./security.nix
    ./steam.nix
    ./sudo.nix
    ./tmux-rebuild.nix
    ./tpm2.nix
    ./user.nix
  ];
}
