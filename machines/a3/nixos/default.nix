{
  imports = [
    ../../../modules/flags
    ../../../modules/nixos/forgejo-mgmt
    ../../../modules/nixos/reposync
    ../../../modules/nixos/syncthing-mgmt
    ../../../modules/nixos/tools
    ./chromium.nix
    ./keyboard.nix
    ./rebuild-diff.nix
    ./sudo.nix
    ../../../system/nix.nix
    ./reposync.nix
    ../../../system/sops-secrets.nix
    ./desktop
    ./server
  ];
}
