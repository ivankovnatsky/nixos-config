{ username, ... }:

{
  imports = [
    ../../modules/darwin/sudo
  ];

  local = {
    sudo = {
      enable = true;
      configContent = ''
        Defaults:${username} timestamp_timeout=240
      '';
    };
  };
}
