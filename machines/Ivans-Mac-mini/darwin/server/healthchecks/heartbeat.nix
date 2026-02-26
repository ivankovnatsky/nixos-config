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
      TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
      ${pkgs.curl}/bin/curl -fsS -m 10 --retry 5 "$(cat ${config.sops.secrets.healthchecks-ping-url.path})" > /dev/null && echo "$TIMESTAMP Ping sent" || echo "$TIMESTAMP Ping failed"
    ''}";
    extraServiceConfig = {
      StartInterval = 60;
    };
  };
}
