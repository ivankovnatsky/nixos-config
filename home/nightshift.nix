{ config, ... }:

{
  services = {
    ${config.variables.nightShiftManager} = {
      enable = true;

      latitude = "49.8";
      longitude = "29.9";

      temperature = {
        day = 5500;
        night = 3700;
      };
    };
  };
}
