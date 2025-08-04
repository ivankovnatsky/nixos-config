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
        user = "${username}";
        commands = [
          "/sbin/shutdown -h now"
          "/sbin/reboot"
        ];
      };
    };
  };
}
