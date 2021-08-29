{
  services = {
    xserver = {
      windowManager.i3.enable = true;

      displayManager = {
        lightdm.enable = true;
        defaultSession = "none+i3";

        autoLogin = {
          enable = true;
          user = "ivan";
        };
      };
    };
  };
}
