{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    clinfo
    docker
    google-chrome
    networkmanagerapplet
    networkmanager-l2tp
    vulkan-tools
  ];
}
