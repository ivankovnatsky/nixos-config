{ super, ... }:

{
  imports = [
    ../modules/flags
    ./git.nix
    ./k9s.nix
    ./packages.nix
    ./shell.nix
    ./ssh.nix
    ./starship
  ];

  inherit (super) device flags;
}
