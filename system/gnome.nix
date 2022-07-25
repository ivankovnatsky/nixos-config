{ pkgs, ... }:

{
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  environment.gnome.excludePackages = (with pkgs; [
    # pixel-saver dependencies
    xorg.xprop
    xorg.xwininfo
    pkgs.epiphany
    pkgs.evince
    gnome-photos
  ]) ++ (with pkgs.gnome; [
    cheese
    gnome-music
    gedit
    gnome-characters
    totem
    tali
    iagno
    hitori
    atomix
    geary
  ]);

  environment.systemPackages = with pkgs; [
    gnomeExtensions.appindicator
    gnome.gnome-tweaks
    gnomeExtensions.quick-lang-switch
    gnomeExtensions.pixel-saver
  ];

  services.udev.packages = with pkgs; [ gnome3.gnome-settings-daemon ];

  hardware.pulseaudio.enable = false;
}
