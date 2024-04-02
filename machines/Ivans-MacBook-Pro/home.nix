{ pkgs, ... }:

{
  imports = [
    ../../home/transmission.nix
    ../../home/workstation.nix
    ../../home/firefox-config.nix
    ../../home/amethyst.nix
    ../../home/vim
    ../../home/lsd.nix
  ];

  variables = {
    purpose = "work";
    editor = "nvim";
    darkMode = false;
  };

  # https://github.com/nix
  programs = {
    direnv = {
      enable = true;
      enableZshIntegration = true; # see note on other shells below
      nix-direnv.enable = true;
    };
  };

  home.packages = with pkgs; [
    aria
    defaultbrowser
    typst
    killport
    kor
    docker-client
  ];
}
