{ pkgs, ... }:

{
  services = {
    xserver = {
      windowManager.i3.enable = true;

      displayManager = {
        lightdm.enable = true;

        autoLogin = {
          enable = true;
          user = "ivan";
        };

        defaultSession = "none+i3";
      };

    };
  };
}
