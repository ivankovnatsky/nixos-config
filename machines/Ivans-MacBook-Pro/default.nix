{
  imports = [
    ./darwin

    ../../darwin/darwin.nix
    ../../darwin/flags.nix
    ../../darwin/fonts.nix
    ../../darwin/homebrew.nix
    ../../darwin/nix.nix
    ../../darwin/security.nix
    ../../darwin/shell.nix
    ../../darwin/sudo.nix
    ../../darwin/system.nix
    ../../darwin/tmux-rebuild.nix
    ../../modules/darwin/dock
    ../../modules/darwin/launchd
    ../../modules/darwin/nextdns-mgmt
    ../../modules/darwin/pam
    ../../modules/darwin/sudo
    ../../modules/darwin/syncthing-mgmt
    ../../modules/darwin/tmux-rebuild
    ../../modules/flags
    ../../system/documentation.nix
    ../../system/nix.nix
    ../../system/scripts
  ];
}
