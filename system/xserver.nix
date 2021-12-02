{ config, ... }:

{
  services = {

    xserver = {
      displayManager = {
        lightdm.enable = true;

        autoLogin = {
          enable = true;
          user = "ivan";
        };
      };
    };

    xserver = {
      enable = true;

      dpi = config.device.xorgDpi;
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
