{ username, ... }:
{
  local.sudo = {
    nopasswd = {
      enable = true;
      user = username;
      setenv = true;
      commands = [
        "/run/current-system/sw/bin/darwin-rebuild switch *"
        "/sbin/shutdown -h now"
      ];
    };
  };
}
