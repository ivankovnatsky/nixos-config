{ pkgs, ... }:

{
  imports = [
    ../../home/transmission.nix
    ../../home/workstation.nix
  ];

  home.packages = with pkgs; [
    defaultbrowser
    typst
    rustc
    packer
  ];
}
