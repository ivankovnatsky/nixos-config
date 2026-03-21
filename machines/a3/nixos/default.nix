{
  imports = [
    # ./gamemode.nix
    ../../../modules/flags
    ../../../modules/nixos/rebuild-daemon
    # ./smb.nix
    ../../../modules/nixos/syncthing-cleaner
    ../../../modules/nixos/syncthing-mgmt
    ../../../nixos/chromium.nix
    ../../../nixos/keyboard.nix
    ../../../nixos/nix-ld.nix
    ../../../nixos/sudo.nix
    ../../../system/nix.nix
    ../../../system/rebuild-daemon.nix
    ./bluetooth.nix
    ./boot.nix
    ./configuration.nix
    ./cryptenroll.nix # TPM2 support for LUKS encryption
    ./default-apps.nix
    ./desktop.nix
    ./dotfiles-sync.nix
    ./fonts.nix
    ./fwupd.nix
    ./gamescope.nix
    ./networking.nix
    ./nixpkgs.nix
    ./nvidia.nix
    ./power-management.nix
    ./power-monitoring.nix
    ./remote-build.nix
    ./security.nix
    ./steam.nix
    ./syncthing-cleaner.nix
    ./syncthing-mgmt.nix
    ./tpm2.nix
    ./user.nix
  ];
}
