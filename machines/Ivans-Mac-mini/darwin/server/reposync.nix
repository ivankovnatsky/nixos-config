{ config, username, ... }:
{
  sops.secrets.discord-webhook-reposync = {
    key = "discord/webhookChannelMonitoringRepoSync";
    owner = username;
  };

  local.services.reposync = {
    enable = true;
    domainFile = config.sops.secrets.external-domain.path;
    discordWebhookFile = config.sops.secrets.discord-webhook-reposync.path;

    repositories = [
      {
        path = "${config.users.users.${username}.home}/Notes";
        remote = "origin";
        remoteUrl = "https://forgejo.@domain@/forgejouser/notes.git";
        branch = "main";
      }
    ];
  };
}
