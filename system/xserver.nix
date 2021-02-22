{ pkgs, ... }:

{
  imports = [ ./i3.nix ];

  environment.variables = {
    GDK_SCALE = "2";
    GDK_DPI_SCALE = "0.5";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    _JAVA_OPTIONS = "-Dsun.java2d.uiScale=2";
  };

  services = {
    autorandr.enable = true;

    xserver = {
      enable = true;

      xautolock = {
        enable = true;
        locker = ''${pkgs.i3lock}/bin/i3lock -c "#000000"'';
      };

      dpi = 192;
      videoDrivers = [ "amdgpu" ];

      desktopManager.xterm.enable = false;

      layout = "us,ua";
      xkbOptions = "grp:caps_toggle";

      libinput = {
        enable = true;

        touchpad = {
          additionalOptions = ''MatchIsTouchpad "on"'';
          naturalScrolling = true;
          tapping = false;
        };
      };

      extraConfig = ''
        Section "InputClass"
          Identifier "My Mouse"
          MatchIsPointer "yes"
          Option "AccelerationProfile" "-1"
          Option "AccelerationScheme" "none"
          Option "AccelSpeed" "-1"
        EndSection

        Section "Monitor"
          Identifier "eDP"
          Option "RightOf" "DisplayPort-1"
          Option "DPMS" "true"
        EndSection

        Section "Monitor"
          Identifier "DisplayPort-1"
          Option "PreferredMode" "3840x2160"
          Option "Position" "0 0"
          Option "LeftOf" "eDP"
          Option "DPMS" "true"
        EndSection
      '';

      deviceSection = ''
        Option "TearFree" "true"
      '';
    };
  };
}
