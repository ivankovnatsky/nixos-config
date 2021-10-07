let
  latitude = builtins.readFile ../.secrets/personal/latitude;
  longitude = builtins.readFile ../.secrets/personal/longitude;
in
{
  services = {
    gammastep = {
      enable = true;
      provider = "geoclue2";

      settings = {
        # otherwise causes funky color tilt
        general = { fade = 0; };
      };

      temperature = {
        day = 5500;
        night = 3700;
      };
    };
  };
}
