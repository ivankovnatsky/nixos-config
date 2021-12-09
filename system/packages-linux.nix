{ config, pkgs, ... }:

let
  chromium-work = pkgs.writeScriptBin "chromium-work" ''
    #!/usr/bin/env bash

    chromium --user-data-dir=/home/ivan/.config/chromium-work
  '';
in
{
  environment.systemPackages = with pkgs; [
    awscli2
    acpi
    binutils-unwrapped
    brightnessctl
    capitaine-cursors
    chromium-work
    dmidecode
    docker
    geteltorito
    gimp
    gnome3.adwaita-icon-theme
    gnome3.libsecret
    gnumake
    google-cloud-sdk
    hwinfo
    imagemagick
    ipcalc
    iw
    killall
    libnotify
    lm_sensors
    lshw
    networkmanagerapplet
    networkmanager-l2tp
    openssl
    openvpn
    update-systemd-resolved
    pavucontrol
    pciutils
    powertop
    strace
    sysstat
    usbutils
    viber
    zip

    (chromium.override {
      commandLineArgs =
        if config.device.graphicsEnv == "xorg" then
          "--force-dark-mode --use-vulkan --enable-gpu-rasterization --flag-switches-begin --enable-features=VaapiVideoDecoder,ReaderMode,HardwareAccelerated,Vulkan,NativeNotifications --flag-switches-end" else
          "--force-dark-mode --use-vulkan --enable-gpu-rasterization --ozone-platform=wayland --flag-switches-begin --enable-features=VaapiVideoDecoder,UseOzonePlatform,ReaderMode,HardwareAccelerated,Vulkan,NativeNotifications,WebRTCPipeWireCapturer --flag-switches-end";
    })
  ];
}
