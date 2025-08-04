{ config, ... }:
{
  security.sudo = {
    enable = true;
    extraConfig = ''
      # Set password timeout to 4 hours (240 minutes)
      Defaults timestamp_timeout=720
      # Wait indefinitely for password input
      Defaults passwd_timeout=0
    '';

    # Configure NOPASSWD rules for specific commands
    extraRules = [
      {
        users = [ "ivan" ];
        commands = [
          {
            command = "/run/current-system/sw/bin/shutdown -h now";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/reboot";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
