{ config, lib, pkgs, username, ... }:

{
  jovian = {
    devices.steamdeck = {
      enable = true;
      enableGyroDsuService = true;
    };

    steam = {
      enable = true;
      autoStart = true;
      user = username;
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
