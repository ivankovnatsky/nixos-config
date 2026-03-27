{
  imports = [
    # ./gamemode.nix
    ../../../modules/flags
    # ./smb.nix
    ../../../modules/nixos/reposync
    ../../../modules/nixos/syncthing-mgmt
    ../../../modules/nixos/tools
    ../../../system/sops-secrets.nix
    ../../../nixos/chromium.nix
    ../../../nixos/keyboard.nix
    ../../../nixos/sudo.nix
    ../../../system/nix.nix
    ../../../system/reposync.nix
    ./bluetooth.nix
    ./boot.nix
    ./configuration.nix
    ./cryptenroll.nix # TPM2 support for LUKS encryption
    ./data-disk.nix
    ./default-apps.nix
    ./desktop.nix
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
    ./reposync.nix
    ./reposync-notes.nix
    ./syncthing-mgmt.nix
    ./tpm2.nix
    ./user.nix
  ];
}
