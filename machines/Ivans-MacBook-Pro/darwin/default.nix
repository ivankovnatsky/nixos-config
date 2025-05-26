{
  imports = [
    # ./promtail.nix
    ../../../darwin/aerospace.nix
    ../../../darwin/darwin.nix
    ../../../darwin/nix.nix
    ../../../darwin/dock.nix
    ../../../darwin/system.nix
    ../../../modules/darwin/dock
    ../../../modules/darwin/pam
    ../../../modules/darwin/sudo
    ../../../modules/darwin/tmux-rebuild
    ../../../modules/flags
    ../../../modules/secrets
    ../../../system/documentation.nix
    ../../../system/nix.nix
    ./cloudflared.nix
    ./flags.nix
    ./fonts.nix
    ./homebrew.nix
    ./security.nix
    ./shell.nix
    ./sudo.nix
    ./tmux-rebuild.nix
  ];
}
