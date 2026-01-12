{ config, pkgs, username, ... }:
let
  homeDir = config.users.users.${username}.home;

  # Git-based repo paths from syncthing-mgmt.nix
  repoPaths = [
    "${homeDir}/Sources/github.com/ivankovnatsky/nixos-config"
    "/Volumes/Storage/Data/Sources"
  ];

  pathArgs = builtins.concatStringsSep " " (map (p: ''"${p}"'') repoPaths);
in
{
  local.launchd.services.clean-syncthing = {
    enable = true;
    type = "user-agent";
    command = "syncthing-cleaner --delete ${pathArgs}";
    runAtLoad = false;
    keepAlive = false;
    waitForPath = "/Volumes/Storage";
    environment = {
      PATH = "/run/current-system/sw/bin:${pkgs.fd}/bin:/usr/bin:/bin";
    };
    extraServiceConfig = {
      # Run every hour
      StartCalendarInterval = [{ Minute = 0; }];
    };
  };
}
