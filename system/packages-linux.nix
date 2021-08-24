{ pkgs, ... }:

let

  chromium-work = pkgs.writeScriptBin "chromium-work" ''
    #!/usr/bin/env bash

    chromium --user-data-dir=/home/ivan/.config/chromium-work
  '';

in
{
  environment.systemPackages = with pkgs; [
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
    gnome3.eog
    gnome3.libsecret
    gnome3.nautilus
    gnumake
    google-cloud-sdk
    hwinfo
    imagemagick
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
    pulseaudio
    strace
    sysstat
    usbutils
    v4l-utils
    vulkan-tools
    xdg-utils
    zip

    (chromium.override {
      commandLineArgs =
        "--force-dark-mode --use-vulkan --enable-gpu-rasterization --ozone-platform=wayland --flag-switches-begin --enable-features=VaapiVideoDecoder,UseOzonePlatform,ReaderMode,HardwareAccelerated,Vulkan,NativeNotifications --flag-switches-end";
    })
  ];
}
