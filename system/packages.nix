{ config, pkgs, ... }:

let
  viber-wayland = pkgs.writeScriptBin "viber-wayland" ''
    #!/usr/bin/env bash

    QT_QPA_PLATFORM=xcb ${pkgs.viber}/bin/viber
  '';
in
{
  environment.systemPackages = with pkgs; [
    viber-wayland
    viber
    acpi
    binutils-unwrapped
    brightnessctl
    dmidecode
    bitwarden-cli
    dnsutils
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
        if config.device.graphicsEnv == "xorg" then
          "--force-dark-mode --use-vulkan --enable-gpu-rasterization --flag-switches-begin --enable-features=VaapiVideoDecoder,ReaderMode,HardwareAccelerated,Vulkan,NativeNotifications --flag-switches-end" else
          "--force-dark-mode --use-vulkan --enable-gpu-rasterization --ozone-platform=wayland --flag-switches-begin --enable-features=VaapiVideoDecoder,UseOzonePlatform,ReaderMode,HardwareAccelerated,Vulkan,NativeNotifications,WebRTCPipeWireCapturer --flag-switches-end";
    })

    (chromium.override {
      commandLineArgs =
        if config.device.graphicsEnv == "xorg" then
          "--force-dark-mode --use-vulkan --enable-gpu-rasterization --flag-switches-begin --enable-features=VaapiVideoDecoder,ReaderMode,HardwareAccelerated,Vulkan,NativeNotifications --flag-switches-end" else
          "--force-dark-mode --use-vulkan --enable-gpu-rasterization --ozone-platform=wayland --flag-switches-begin --enable-features=VaapiVideoDecoder,UseOzonePlatform,ReaderMode,HardwareAccelerated,Vulkan,NativeNotifications,WebRTCPipeWireCapturer --flag-switches-end";
    })
  ];
}
