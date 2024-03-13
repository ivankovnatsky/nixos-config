{ pkgs, ... }:

{
  imports = [
    ../../home/transmission.nix
    ../../home/workstation.nix
    ../../home/firefox-config.nix
    ../../home/amethyst.nix
    ../../home/vim
  ];

  variables = {
    purpose = "work";
    editor = "nvim";
    darkMode = false;
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
