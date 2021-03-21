{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    clinfo
    docker
    (chromium.override {
      commandLineArgs =
        "--force-dark-mode --flag-switches-begin --enable-features=ReaderMode,HardwareAccelerated,Vulkan,NativeNotifications --flag-switches-end";
    })
    networkmanagerapplet
    networkmanager-l2tp
    vulkan-tools
  ];
}
