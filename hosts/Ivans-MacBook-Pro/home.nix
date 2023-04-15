{ pkgs, ... }:

{
  imports = [
    ../../home/transmission.nix
    ../../home/workstation.nix
  ];

  home.packages = with pkgs; [
    defaultbrowser
    eks-node-viewer
    pv-migrate
    granted
    kubectl-ktop
    typst

    rustc

    packer
  ];
}
