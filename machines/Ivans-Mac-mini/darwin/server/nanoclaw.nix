{
  config,
  pkgs,
  username,
  ...
}:

let
  nanoclawDataPath = "${config.flags.externalStoragePath}/.nanoclaw";
in
{
  local.launchd.services.nanoclaw = {
    enable = true;
    type = "user-agent";
    waitForPath = config.flags.externalStoragePath;
    dataDir = nanoclawDataPath;
    environment = {
      HOME = config.users.users.${username}.home;
      PATH = "${pkgs.nanoclaw}/bin:${pkgs.container}/bin:/usr/local/bin:/usr/bin:/bin";
      NODE_ENV = "production";
      NANOCLAW_HOME = nanoclawDataPath;
      CREDENTIAL_PROXY_PORT = "3002";
    };
    command = "${pkgs.nanoclaw}/bin/nanoclaw";
  };
}
