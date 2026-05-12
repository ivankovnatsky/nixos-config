{
  imports = [
    ../../../modules/flags
    ../../../modules/nixos/forgejo-mgmt
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
    ./desktop
    ./server
  ];
}
