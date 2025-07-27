{
  imports = [
    ../../modules/nixos/tmux-rebuild
    ./tmux-rebuild.nix

    # Other configurations
    ./configuration.nix
    ./nvidia.nix
    ./nixpkgs.nix
    ./gnupg.nix
    # ./gnome.nix
    ./kde.nix
    ./gui.nix
    ./sudo.nix
    ./user.nix
    ./steam.nix
    ./fonts.nix
    ./packages.nix

    # TPM2 support for LUKS encryption
    ./cryptenroll.nix
    ./tpm2.nix

    ../../system/nix.nix
  ];
}
