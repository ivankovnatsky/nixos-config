{ ... }:

{

  programs.home-manager.enable = true;

  home.username = "ivan";
  home.homeDirectory = "/home/ivan";

  imports = [
    ./modules/packages.nix
    ./modules/programs.nix
    ./modules/services.nix

    ./modules/alacritty.nix
    ./modules/autorandr.nix
    ./modules/gtk.nix
    ./modules/git.nix
    ./modules/i3.nix
    ./modules/i3status.nix
    ./modules/neovim.nix
    ./modules/tmux.nix
    ./modules/zsh.nix
  ];

  nixpkgs.config = { allowUnfree = true; };

  home.file = {

    ".config/ranger/rc.conf" = {
      text = ''
        set show_hidden true
      '';
    };

  };

  home.stateVersion = "21.03";

}
