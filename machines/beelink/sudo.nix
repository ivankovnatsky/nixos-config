{
  security.sudo = {
    enable = true;
    extraConfig = ''
      # Set password timeout to 2 hours (7200 seconds)
      Defaults timestamp_timeout=7200
    '';
  };
}
