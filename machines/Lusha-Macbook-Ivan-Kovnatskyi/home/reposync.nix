{ config, ... }:
{
  sops.secrets.discord-webhook-reposync = {
    key = "discord/webhooks/monitoringRepoSync";
  };

  local.services.reposync = {
    enable = true;
    discordWebhookFile = config.sops.secrets.discord-webhook-reposync.path;

    repositories = [
      {
        path = "${config.home.homeDirectory}/Sources/github.com/ivankovnatsky/nix-config";
        remote = "origin";
        remoteUrl = "https://github.com/ivankovnatsky/nix-config.git";
        branch = "main";
      }
    ];
  };
}
