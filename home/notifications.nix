{ config, ... }:
{
  local.services.notifications = {
    discordWebhookFile = config.sops.secrets.discord-webhook-notifications.path;

    battery = {
      enable = true;
      dailyAt = "21:00";
      belowPercent = 50;
      lowIntervalHours = 3;
    };
  };
}
