{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    clinfo
    docker
    (chromium.override { commandLineArgs = "--force-dark-mode"; })
    networkmanagerapplet
    networkmanager-l2tp
    vulkan-tools
  ];
}
