{ config, username, ... }:

let
  homePath = "${config.users.users.${username}.home}";
in
{
  local.services.syncthing-mgmt.folders = { };
}
