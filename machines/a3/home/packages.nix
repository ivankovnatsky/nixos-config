{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nvtopPackages.nvidia # GPU monitoring (like htop for GPUs)
    discordo
    find-grep
    gpg-pass-refresh
    rg-all
    rg-find
    taskmanager
    velocidrone
  ];
}
