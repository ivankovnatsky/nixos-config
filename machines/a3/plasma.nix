{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Trying out Plasma because it handles Steam games at higher than 1920x1080
  # resolutions much expected, whereas in GNOME all games are capped at that
  # resolution.

  # And overall I see that configuring Qt apps are much more pleasant than GNOME.
  services = {
    desktopManager.plasma6.enable = true;
    displayManager.sddm = {
      enable = true;
      wayland.enable = false;
      settings = {
        General = {
          GreeterEnvironment = "QT_SCREEN_SCALE_FACTORS=2,QT_FONT_DPI=192";
        };
      };
    };
  };
}
