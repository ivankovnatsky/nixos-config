{ username, ... }:
{
  local.sudo = {
    nopasswd = {
      enable = true;
      user = username;
      commands = [
        "/run/current-system/sw/bin/darwin-rebuild"
      ];
    };
  };
}
