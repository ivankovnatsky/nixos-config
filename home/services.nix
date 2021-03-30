{ pkgs, ... }:

{
  services = {
    gpg-agent.enable = true;

    gammastep = {
      enable = true;
      provider = "geoclue2";

      temperature = {
        day = 5500;
        night = 3700;
      };
    };
  };
}
