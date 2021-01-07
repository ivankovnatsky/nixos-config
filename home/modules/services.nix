{ ... }:

{
  services = {
    redshift = {
      enable = true;
      provider = "geoclue2";

      brightness = {
        # Note the string values below.
        day = "1";
        night = "1";
      };

      temperature = {
        day = 5500;
        night = 3700;
      };
    };

  };
}
