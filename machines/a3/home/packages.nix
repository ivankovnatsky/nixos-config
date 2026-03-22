{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nvtopPackages.nvidia # GPU monitoring (like htop for GPUs)
    discordo
    find-grep
    rg-all
    rg-find
    taskmanager
    velocidrone
  ];
}
