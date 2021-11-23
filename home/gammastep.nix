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
