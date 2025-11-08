{
  config,
  lib,
  pkgs,
  ...
}:

{
  services = {
    desktopManager.plasma6.enable = true;
    displayManager.sddm = {
      # Disable SDDM when jovian.steam.autoStart is enabled
      enable = !config.jovian.steam.autoStart;
      wayland.enable = false;
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
    config.common.default = "*";
  };

  environment.systemPackages = with pkgs; [
    maliit-keyboard
    maliit-framework
  ];
}
