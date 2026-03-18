{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nvtopPackages.nvidia # GPU monitoring (like htop for GPUs)
    find-grep
    rg-all
    rg-find
    syncthing-cleaner
    taskmanager
    velocidrone
  ];
}
