{ pkgs, ... }:

{
  imports = [
    ../../home/transmission.nix
    ../../home/workstation.nix
  ];

  home.packages = with pkgs; [
    aria
    defaultbrowser
    typst
    killport
  ];
}
