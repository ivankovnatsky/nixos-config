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

  };
}
