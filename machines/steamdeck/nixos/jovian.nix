{ config, lib, pkgs, ... }:

{
  jovian = {
    devices.steamdeck = {
      enable = true;
      enableGyroDsuService = true;
    };

    steam = {
      enable = true;
      autoStart = true;
      desktopSession = "plasma";
    };

    decky-loader = {
      enable = false;
    };

    steamos = {
      useSteamOSConfig = false;
    };
  };
}
