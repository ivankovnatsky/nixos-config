{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nvtopPackages.nvidia # GPU monitoring (like htop for GPUs)
    velocidrone
  ];
}
