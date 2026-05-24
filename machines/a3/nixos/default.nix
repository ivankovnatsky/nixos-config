{
  imports = [
    ../../../modules/flags
    ../../../modules/nixos/forgejo-mgmt
    ../../../modules/nixos/reposync
    ../../../modules/nixos/syncthing-mgmt
    ../../../modules/nixos/tools
    ../../../system/nix.nix
    ../../../system/sops-secrets.nix
    ./chromium.nix
    ./desktop
    ./keyboard.nix
    ./rebuild-diff.nix
    ./reposync.nix
    ./server
    ./sudo.nix
  ];
}
