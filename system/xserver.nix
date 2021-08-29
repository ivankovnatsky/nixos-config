{ config, ... }:

{
  environment.variables = {
    GDK_SCALE = "2";
    GDK_DPI_SCALE = "0.5";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    _JAVA_OPTIONS = "-Dsun.java2d.uiScale=2";
  };

  services = {
    xserver = {
      enable = true;

      dpi = 192;
      videoDrivers = [ config.device.videoDriver ];

      desktopManager.xterm.enable = false;

      layout = "us,ua";
      xkbOptions = "grp:caps_toggle";

      extraConfig = ''
        Section "InputClass"
          Identifier "My Mouse"
          MatchIsPointer "yes"
          Option "AccelerationProfile" "-1"
          Option "AccelerationScheme" "none"
          Option "AccelSpeed" "-1"
        EndSection
      '';
    };
  };
}
