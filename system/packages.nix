{ config, pkgs, ... }:

let
  chromium-work = pkgs.writeScriptBin "chromium-work" ''
    #!/usr/bin/env bash

    chromium --user-data-dir=/home/ivan/.config/chromium-work
  '';
in
{
  environment.systemPackages = with pkgs; [
    _1password
    acpi
    binutils-unwrapped
    brightnessctl
    chromium-work
    dmidecode
    dnsutils
    docker
    docker-compose
    geteltorito
    gimp
    git
    gnome3.adwaita-icon-theme
    gnome3.libsecret
    google-cloud-sdk
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
    powertop
    strace
    sysstat
    update-systemd-resolved
    usbutils
    viber

    (chromium.override {
      commandLineArgs =
        if config.device.graphicsEnv == "xorg" then
          "--force-dark-mode --use-vulkan --enable-gpu-rasterization --flag-switches-begin --enable-features=VaapiVideoDecoder,ReaderMode,HardwareAccelerated,Vulkan,NativeNotifications --flag-switches-end" else
          "--force-dark-mode --use-vulkan --enable-gpu-rasterization --ozone-platform=wayland --flag-switches-begin --enable-features=VaapiVideoDecoder,UseOzonePlatform,ReaderMode,HardwareAccelerated,Vulkan,NativeNotifications,WebRTCPipeWireCapturer --flag-switches-end";
    })
  ];
}
