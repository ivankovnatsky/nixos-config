{ config, ... }:
{
  local.services.notifications = {
    discordWebhookFile = config.sops.secrets.discord-webhook-notifications.path;

    battery = {
      enable = true;
      at = "21:00";
    };

    # Flush reposync/rebuild failures recorded during the day in one batch.
    digest = {
      enable = true;
      at = "21:00";
    };
  };
}
