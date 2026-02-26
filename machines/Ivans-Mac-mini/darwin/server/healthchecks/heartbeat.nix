{
  config,
  pkgs,
  username,
  ...
}:

{
  sops.secrets.healthchecks-ping-url = {
    key = "healthChecksIo/pingUrl";
    owner = username;
  };

  local.launchd.services.heartbeat = {
    enable = true;
    type = "user-agent";
    waitForSecrets = true;
    keepAlive = false;
    runAtLoad = true;
    command = "${pkgs.writeShellScript "heartbeat-ping" ''
      ${pkgs.curl}/bin/curl -fsS -m 10 --retry 5 "$(cat ${config.sops.secrets.healthchecks-ping-url.path})" > /dev/null
    ''}";
    extraServiceConfig = {
      StartInterval = 60;
    };
  };
}
