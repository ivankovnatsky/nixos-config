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
    }
    {
      path = "${config.flags.externalStoragePath}/Sources/github.com/ivankovnatsky/nix-config";
      remote = "origin";
      remoteUrl = "https://github.com/ivankovnatsky/nix-config.git";
      branch = "main";
    }
    {
      path = "${config.flags.externalStoragePath}/Sources/github.com/openclaw/openclaw";
      remote = "origin";
      remoteUrl = "https://github.com/openclaw/openclaw.git";
      branch = "main";
      syncMode = "pull-only";
      prune = true;
    }
    {
      path = "${config.flags.externalStoragePath}/Notes";
      remote = "origin";
      remoteUrl = "https://forgejo.@domain@/@username@/notes.git";
      branch = "main";
    }
  ];
}
