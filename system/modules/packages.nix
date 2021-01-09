{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    clinfo
    ofono-phonesim
    docker
    google-chrome
    networkmanagerapplet
    networkmanager-l2tp
    vulkan-tools
  ];
}
