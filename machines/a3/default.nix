{
  imports = [
    ../../modules/nixos/tmux-rebuild
    ./tmux-rebuild.nix

    # Other configurations
    ./configuration.nix
    ./boot.nix
    ./nvidia.nix
    ./nixpkgs.nix
    # ./gnome.nix
    ./kde.nix
    ./gui.nix
    ./security.nix
    ./sudo.nix
    ./user.nix
    ./steam.nix
    ./fonts.nix
    ./packages.nix
    ./bluetooth.nix

    # TPM2 support for LUKS encryption
    ./cryptenroll.nix
    ./tpm2.nix

    ../../system/nix.nix
  ];
}
