{ super, ... }:

{
  imports = [
    ./k9s.nix
    ./git.nix
    ./ssh.nix
    ./packages.nix
    ./shell.nix
    ./starship.nix

    ../modules/flags
  ];

  inherit (super) device flags;
}
