{
  security = {
    rtkit.enable = true;
    sudo.configFile = ''
      Defaults timestamp_timeout=240
    '';
  };
}
