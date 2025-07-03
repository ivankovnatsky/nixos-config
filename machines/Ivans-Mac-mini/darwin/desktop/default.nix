{
  imports = [
    ../../../../darwin/darwin.nix

    ./dock.nix

    ../../../../darwin/flags.nix
    ../../../../darwin/fonts.nix

    ./homebrew.nix

    ../../../../darwin/shell.nix
    ../../../../darwin/sudo.nix
    ../../../../darwin/system.nix
    ../../../../darwin/user.nix
    ../../../../modules/darwin/dock
    ../../../../modules/darwin/pam
    ../../../../modules/darwin/sudo
    ../../../../modules/flags
    ../../../../modules/secrets
    ../../../../system/documentation.nix
    ../../../../system/nix.nix
  ];
}
