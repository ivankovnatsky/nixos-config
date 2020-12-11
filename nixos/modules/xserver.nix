{ pkgs, ... }:

{
  services = {
    xserver = {
      enable = true;

      dpi = 192;
      videoDrivers = [ "amdgpu" ];

      xautolock = {
        enable = true;
        locker = "${pkgs.slock}/bin/slock";
      };

      displayManager = {
        lightdm.enable = true;

        autoLogin = {
          enable = true;
          user = "sevenfourk";
        };

        defaultSession = "xsession";

        sessionCommands = ''
          st -e tmux attach || st -e tmux &
          # sleep 10 && chromium &
          chromium &

          while true; do slstatus 2> /tmp/slstatus-log; done &
        '';

        session = [{
          manage = "desktop";
          name = "xsession";
          start = "while true; do dwm 2> /tmp/dwm-log; done";
        }];
      };

      layout = "us,ua";
      xkbOptions = "grp:caps_toggle";

      libinput = {
        enable = true;
        tapping = false;
        naturalScrolling = true;
        additionalOptions = ''MatchIsTouchpad "on"'';
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
