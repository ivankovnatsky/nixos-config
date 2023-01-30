{ pkgs, ... }:

{
  imports = [
  ];

  home.packages = with pkgs; [
    eks-node-viewer
    pv-migrate

    transmission-qt
    rustc
  ];
}
