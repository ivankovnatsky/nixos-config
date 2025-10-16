{ username, ... }:
{
  local = {
    sudo = {
      enable = true;
      configContent = ''
        Defaults:${username} timestamp_timeout=720
      '';
      nopasswd = {
        enable = true;
        user = username;
        setenv = true;
        commands = [
          "/run/current-system/sw/bin/darwin-rebuild switch *"
        ];
      };
    };
  };
}
