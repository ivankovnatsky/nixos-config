{ pkgs, ... }:

{
  imports = [
  ];

  home.packages = with pkgs; [
    defaultbrowser
    eks-node-viewer
    pv-migrate

    transmission-qt
    rustc
  ];
}
