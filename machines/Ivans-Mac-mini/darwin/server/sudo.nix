{ username, ... }:

{
  local = {
    sudo = {
      enable = true;
      configContent = ''
        Defaults:${username} timestamp_timeout=240
      '';
      nopasswd = {
        enable = true;
        user = "${username}";
        commands = [
          "/sbin/shutdown -h now"
          "/sbin/reboot"
        ];
      };
    };
  };
}
