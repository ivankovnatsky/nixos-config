{ config, username, ... }:
let
  homePath = config.users.users.${username}.home;
in
{
  local.services.syncthing-cleaner = {
    enable = true;
    intervalMinutes = 15;
    paths = [
      "${homePath}/.config/rclone"
      "${homePath}/.password-store"
      "${homePath}/Sources"
    ];
  };
}
