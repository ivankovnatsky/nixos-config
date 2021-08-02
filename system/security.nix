{
  security = {
    rtkit.enable = true;
    pam.services.swaylock = { };
    sudo.configFile = ''
      Defaults timestamp_timeout=240
    '';
  };
}
