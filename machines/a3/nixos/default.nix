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
    ../../../nixos/rebuild-diff.nix
    ../../../nixos/sudo.nix
    ../../../system/nix.nix
    ../../../system/reposync.nix
    ../../../system/sops-secrets.nix
    ./bluetooth.nix
    ./boot.nix
    ./configuration.nix
    ./cryptenroll.nix # TPM2 support for LUKS encryption
    ./default-apps.nix
    ./desktop.nix
    ./fonts.nix
    ./fwupd.nix
    ./gamescope.nix
    ./networking.nix
    ./nextdns.nix
    ./nixpkgs.nix
    ./nvidia.nix
    ./ollama.nix
    ./power-management.nix
    ./power-monitoring.nix
    ./remote-build.nix
    ./reposync.nix
    ./security.nix
    ./server
    ./stash.nix
    ./steam.nix
    ./storage-disk.nix
    ./syncthing-mgmt.nix
    ./tpm2.nix
    ./user.nix
  ];
}
