{ config, username, ... }:

let
  homePath = "${config.users.users.${username}.home}";
in
{
  local.services.syncthing-mgmt.folders = {
    "dotfiles-shared" = {
      path = "${homePath}/Sources/github.com/ivankovnatsky-local/dotfiles-shared";
      label = "Sources/github.com/ivankovnatsky-local/dotfiles-shared";
      devices = [
        "Ivans-MacBook-Pro"
        "Lusha-Macbook-Ivan-Kovnatskyi"
      ];
    };
  };
}
