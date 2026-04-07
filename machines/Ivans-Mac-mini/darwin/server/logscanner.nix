{ config, ... }:
{
  sops.secrets.discord-webhook-logscanner = {
    key = "discord/webhooks/monitoringLogs";
    mode = "0444";
  };

  local.services.logscanner = {
    enable = true;
    hour = 21;
    minute = 0;
    discordWebhookFile = config.sops.secrets.discord-webhook-logscanner.path;
    logPaths = [
      "/tmp/log/launchd/*.log"
      "/tmp/log/launchd/*.error.log"
      "/tmp/log/caddy/*.log"
      "/tmp/log/dnsmasq/*.log"
      "/tmp/log/logrotate/*.log"
    ];
  };
}
