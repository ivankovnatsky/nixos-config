{ pkgs, ... }:

{
  imports = [
    ../../home/transmission.nix
  ];

  home.packages = with pkgs; [
    defaultbrowser
    eks-node-viewer
    pv-migrate

    rustc

    packer
  ];
}
