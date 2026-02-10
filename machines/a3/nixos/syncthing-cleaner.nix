{ config, username, ... }:
let
  homePath = config.users.users.${username}.home;
in
{
  local.services.syncthing-cleaner = {
    enable = true;
    intervalMinutes = 15;
    user = username;
    paths = [
      "${homePath}/Sources"
    ];
  };
}
