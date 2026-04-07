{ config, ... }:
{
  sops.secrets.discord-webhook-logscanner = {
    key = "discord/webhooks/monitoringLogs";
  };

  local.services.logscanner = {
    enable = true;
    hour = 21;
    minute = 5;
    discordWebhookFile = config.sops.secrets.discord-webhook-logscanner.path;
    logPaths = [
      "/tmp/agents/log/launchd/*.log"
      "/tmp/agents/log/launchd/*.error.log"
      "${config.flags.externalStoragePath}/.*/logs/*.log"
    ];
  };
}
