{
  services = {
    gammastep = {
      enable = true;

      latitude = "49.80,";
      longitude = "29.98";

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
