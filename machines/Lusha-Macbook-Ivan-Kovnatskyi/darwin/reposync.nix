{ config, username, ... }:
{
  sops.secrets.discord-webhook-reposync = {
    key = "discord/webhookChannelMonitoringRepoSync";
    owner = username;
  };

  local.services.reposync = {
    enable = true;
    discordWebhookFile = config.sops.secrets.discord-webhook-reposync.path;

    repositories = [
      {
        path = "${config.users.users.${username}.home}/Sources/github.com/ivankovnatsky/nix-config";
        remote = "origin";
        remoteUrl = "https://github.com/ivankovnatsky/nix-config.git";
        branch = "main";
      }
    ];
  };
}
