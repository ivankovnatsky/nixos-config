{ config, username, ... }:
{
  security.sudo = {
    enable = true;
    extraConfig = ''
      Defaults timestamp_timeout=720
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
        ];
      }
    ];
  };
}
