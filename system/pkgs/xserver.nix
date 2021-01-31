{ pkgs, ... }:

{
  services = {
    xserver = {
      enable = true;

      xautolock = {
        enable = true;
        locker = "${pkgs.i3lock}/bin/i3lock";
      };

      dpi = 192;
      videoDrivers = [ "amdgpu" ];

      desktopManager.xterm.enable = false;

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
