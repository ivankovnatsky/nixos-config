{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    autocutsel
    clinfo
    docker
    home-manager
    networkmanagerapplet
    networkmanager-l2tp
    vulkan-tools

    (google-chrome.override {
      commandLineArgs = "--enable-accelerated-video-decode --enable-vulkan";
    })
  ];
}
