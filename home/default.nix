{ super, ... }:

{
  imports = [
    ./k9s.nix
    ./neovim
    ./git.nix
    ./ssh.nix
    ./packages.nix
    ./shell.nix

    ../modules/flags
  ];

  inherit (super) device flags;
}
