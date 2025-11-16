{
  imports = [
    # ./gamemode.nix
    # ./gamescope.nix
    ./nvidia.nix
    # ./smb.nix
    ../../../modules/flags
    ../../../modules/nixos/rebuild-daemon
    ../../../modules/nixos/syncthing-mgmt
    ../../../nixos/chromium.nix
    ../../../nixos/keyboard.nix
    ../../../system/nix.nix
    ../../../system/rebuild-daemon.nix
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
    ./remote-build.nix
    ./security.nix
    ./steam.nix
    ../../../nixos/sudo.nix
    ./syncthing-mgmt.nix
    ./tpm2.nix
    ./user.nix
  ];
}
