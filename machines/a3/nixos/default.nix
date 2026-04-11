{
  imports = [
    # ./gamemode.nix
    ../../../modules/flags
    # ./smb.nix
    ../../../modules/nixos/reposync
    ../../../modules/nixos/syncthing-mgmt
    ../../../modules/nixos/tools
    ../../../nixos/chromium.nix
    ../../../nixos/keyboard.nix
    ../../../nixos/sudo.nix
    ../../../system/nix.nix
    ../../../system/reposync.nix
    ../../../system/sops-secrets.nix
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
    ./ollama.nix
    ./power-management.nix
    ./power-monitoring.nix
    ./remote-build.nix
    ./reposync-notes.nix
    ./reposync.nix
    ./security.nix
    ./steam.nix
    ./syncthing-mgmt.nix
    ./tpm2.nix
    ./user.nix
  ];
}
