{ config, ... }:
{
  security.sudo = {
    enable = true;
    extraConfig = ''
      # Set password timeout to 2 hours (7200 seconds)
      Defaults timestamp_timeout=7200
    '';
    
    # Configure NOPASSWD rules for specific commands
    extraRules = [
      {
        users = [ "ivan" ];
        commands = [
          {
            command = "/run/current-system/sw/bin/nixos-rebuild";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${config.system.build.nixos-rebuild}/bin/nixos-rebuild";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
