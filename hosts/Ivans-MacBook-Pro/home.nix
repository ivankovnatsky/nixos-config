{ pkgs, ... }:

{
  imports = [
  ];

  home.packages = with pkgs; [
    eks-node-viewer
  ];
}
