{
  config,
  username,
  ...
}:

{
  sops.secrets.healthchecks-api-key = {
    key = "healthChecksIo/apiKeyFullAccess";
    owner = username;
  };

  local.services.healthchecks-mgmt = {
    enable = true;
    apiKeyFile = config.sops.secrets.healthchecks-api-key.path;
    checks = [
      {
        name = "mini-heartbeat";
        slug = "mini-heartbeat";
        tags = "mini server";
        timeout = 120;
        grace = 60;
        channels = "*";
      }
    ];
  };
}
