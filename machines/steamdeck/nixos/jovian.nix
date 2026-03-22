{ username, ... }:

{
  # Work around boot race: steamos-manager can timeout on first start,
  # causing steamosctl set-default-desktop-session to hang indefinitely,
  # which blocks graphical-session.target and prevents Steam from launching.
  systemd.user.services.jovian-setup-desktop-session = {
    overrideStrategy = "asDropin";
    serviceConfig = {
      TimeoutStartSec = 30;
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  jovian = {
    devices.steamdeck = {
      enable = true;
      autoUpdate = true;
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
      useSteamOSConfig = true;
    };
  };
}
