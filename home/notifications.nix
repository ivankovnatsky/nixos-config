{ config, ... }:
{
  local.services.notifications = {
    discordWebhookFile = config.sops.secrets.discord-webhook-notifications.path;

    battery = {
      enable = true;
      at = "21:00";
    };
  };
}
