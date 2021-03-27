{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    clinfo
    docker
    (chromium.override {
      commandLineArgs =
        "--force-dark-mode --use-vulkan --enable-gpu-rasterization --flag-switches-begin --enable-features=ReaderMode,HardwareAccelerated,Vulkan,NativeNotifications --flag-switches-end";
    })
    networkmanagerapplet
    networkmanager-l2tp
    vulkan-tools

    terraform-custom
  ];
}
