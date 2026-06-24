{
  pkgs,
  ...
}:

{
  # Trying out Plasma because it handles Steam games at higher than 1920x1080
  # resolutions much expected, whereas in GNOME all games are capped at that
  # resolution.

  # And overall I see that configuring Qt apps are much more pleasant than GNOME.

  # Suppress noisy Qt/QML warnings (qmlRegisterType absolute URLs, portal registration)
  environment.sessionVariables.QT_LOGGING_RULES = "default.warning=false;qt.qml.typeregistration.warning=false;qt.qpa.services.warning=false";

  # Plasma 6 enables services.fwupd by default (Discover firmware updates).
  # This is a server; disable it to stop fwupd-refresh.service from failing.
  services.fwupd.enable = false;

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

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
    config.common.default = "*";
  };

  # Broadcast cursor theme/size to non-Qt apps (GTK, legacy X11). Plasma calls
  # these at session start to propagate XSETTINGS / Xresources; without them
  # the broadcast silently no-ops and apps fall back to the 24px default.
  # https://discourse.nixos.org/t/49917
  environment.systemPackages = with pkgs; [
    xsettingsd
    xrdb
  ];
}
