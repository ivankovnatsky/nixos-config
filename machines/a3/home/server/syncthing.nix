{
  config,
  ...
}:

{
  # Enable Syncthing service for user
  services.syncthing = {
    enable = true;
    guiAddress = "${config.flags.a3Ip}:8384";
  };
}
