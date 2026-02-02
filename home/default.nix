{ super, ... }:

{
  imports = [
    ../modules/flags
    ./git
    ./k9s.nix
    ./packages-darwin.nix
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
