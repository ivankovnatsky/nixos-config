{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    clinfo
    docker
    (google-chrome.override { commandLineArgs = "--force-dark-mode"; })
    networkmanagerapplet
    networkmanager-l2tp
    vulkan-tools
  ];
}
