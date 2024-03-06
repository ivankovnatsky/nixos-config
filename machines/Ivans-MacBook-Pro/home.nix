{ pkgs, ... }:

{
  imports = [
    ../../home/transmission.nix
    ../../home/workstation.nix
    ../../home/firefox-config.nix
  ];

  home.packages = with pkgs; [
    aria
    defaultbrowser
    typst
    killport
    kor
    docker-client
  ];
}
