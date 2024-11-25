{ super, ... }:

{
  imports = [
    ./k9s.nix
    ./git.nix
    ./ssh.nix
    ./packages.nix
    ./shell.nix
    ./starship

    ../modules/flags
  ];

  inherit (super) device flags;
}
