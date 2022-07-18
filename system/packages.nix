{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    acpi
    binutils-unwrapped
    brightnessctl
    dmidecode
    dnsutils
    docker
    docker-compose
    geteltorito
    gimp
    git
    gnome3.adwaita-icon-theme
    libsecret
    hwinfo
    iw
    libnotify
    lm_sensors
    lshw
    neovim
    networkmanagerapplet
    networkmanager-l2tp
    pavucontrol
    pciutils
    strace
    sysstat
    update-systemd-resolved
    usbutils

    (google-chrome.override {
      commandLineArgs =
        "--force-dark-mode --use-vulkan --enable-gpu-rasterization --ozone-platform=wayland --flag-switches-begin --enable-features=VaapiVideoDecoder,UseOzonePlatform,ReaderMode,HardwareAccelerated,Vulkan,NativeNotifications,WebRTCPipeWireCapturer --flag-switches-end";
    })

    (chromium.override {
      commandLineArgs =
        "--force-dark-mode --use-vulkan --enable-gpu-rasterization --ozone-platform=wayland --flag-switches-begin --enable-features=VaapiVideoDecoder,UseOzonePlatform,ReaderMode,HardwareAccelerated,Vulkan,NativeNotifications,WebRTCPipeWireCapturer --flag-switches-end";
    })
  ];
}
