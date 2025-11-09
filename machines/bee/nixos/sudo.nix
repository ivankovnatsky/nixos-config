{ config, username, ... }:
{
  security.sudo = {
    enable = true;
    extraConfig = ''
      # Set password timeout to 4 hours (240 minutes)
      Defaults timestamp_timeout=720
      # Wait indefinitely for password input
      Defaults passwd_timeout=0
    '';
    extraRules = [
      {
        users = [ username ];
        commands = [
          {
            command = "${config.system.build.nixos-rebuild}/bin/nixos-rebuild switch *";
            options = [ "NOPASSWD" "SETENV" ];
          }
          {
            command = "/etc/profiles/per-user/${username}/bin/shutdown -h now";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
