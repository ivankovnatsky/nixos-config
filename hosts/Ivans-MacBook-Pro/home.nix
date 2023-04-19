{ pkgs, ... }:

{
  imports = [
    ../../home/transmission.nix
    ../../home/workstation.nix
    ../../home/vim
  ];

  home.packages = with pkgs; [
    defaultbrowser
    eks-node-viewer
    pv-migrate
    granted
    kubectl-ktop
    typst
    tfupdate

    rustc

    packer
  ];
}
