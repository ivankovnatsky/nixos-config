{ config, username, ... }:

let
  homePath = "${config.users.users.${username}.home}";
in
{
  local.services.syncthing-mgmt.folders = {
    "nix-config-ignored-files" = {
      path = "${config.users.users.${username}.home}/Sources/github.com/ivankovnatsky/nix-config-ignored-files";
      label = "nix-config-ignored-files";
      devices = [
        "Ivans-Mac-mini"
        "Ivans-MacBook-Pro"
        "Ivans-MacBook-Air"
        "Lusha-Macbook-Ivan-Kovnatskyi"
        "a3"
        "steamdeck"
      ];
    };
  };
}
