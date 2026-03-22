{ username, ... }:

{
  # Work around boot race: steamos-manager can timeout on first start,
  # causing steamosctl set-default-desktop-session to hang indefinitely,
  # which blocks graphical-session.target and prevents Steam from launching.
  #
  # Do NOT use overrideStrategy = "asDropin" here. It causes NixOS to emit
  # the merged service as a dropin only (no base unit file), and systemd
  # ignores dropins without a base unit — the service becomes not-found,
  # breaking both Steam launch and "Switch to Desktop".
  systemd.user.services.jovian-setup-desktop-session = {
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
