{ config, ... }:
{
  sops.secrets.discord-webhook-reposync = {
    key = "discord/webhooks/monitoringRepoSync";
  };

  local.services.reposync = {
    enable = true;
    alertStateFile = "${config.home.homeDirectory}/.local/state/reposync/alerts.json";
    domainFile = config.sops.secrets.external-domain.path;
    usernameFile = config.sops.secrets.forgejo-user-name.path;
    discordWebhookFile = config.sops.secrets.discord-webhook-reposync.path;
  };

  local.services.reposync.repositories = [
    {
      name = "home";
      path = config.home.homeDirectory;
      remote = "origin";
      remoteUrl = "https://forgejo.@domain@/@username@/home.git";
      branch = "main";
      identity = {
        name = "@username@";
        email = "@username@@@domain@";
        signingKey = "@username@@@domain@";
      };
    }
    {
      path = "${config.flags.homeWorkPath}/Sources/github.com/ivankovnatsky/nix-config";
      remote = "origin";
      remoteUrl = "https://github.com/ivankovnatsky/nix-config.git";
      branch = "main";
    }
  ];
}
