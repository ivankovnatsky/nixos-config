{ super, ... }:

{
  imports = [
    ../modules/flags
    ./git.nix
    ./k9s.nix
    ./packages.nix
    ./atuin.nix
    ./fish.nix
    ./fzf.nix
    ./z-lua.nix
    ./zsh.nix
    ./ssh.nix
    ./starship
  ];

  inherit (super) device flags;
}
