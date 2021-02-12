{ ... }:

{
  services = {
    gpg-agent = {
      enable = true;
      enableSshSupport = true;
    };

    redshift = {
      enable = true;
      provider = "geoclue2";

      temperature = {
        day = 5500;
        night = 3700;
      };
    };

  };
}
