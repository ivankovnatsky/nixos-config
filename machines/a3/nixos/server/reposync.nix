{ config, username, ... }:
{
  sops.secrets.discord-webhook-reposync = {
    key = "discord/webhooks/monitoringRepoSync";
    owner = username;
  };

  local.services.reposync = {
    enable = true;
    alertStateFile = "/home/${username}/.local/state/reposync/alerts.json";
    domainFile = config.sops.secrets.external-domain.path;
    usernameFile = config.sops.secrets.forgejo-user-name.path;
    discordWebhookFile = config.sops.secrets.discord-webhook-reposync.path;

    repositories = [
      {
        name = "home";
        path = "${config.users.users.${username}.home}";
        remote = "origin";
        remoteUrl = "https://forgejo.@domain@/@username@/home.git";
        branch = "main";
      }
      {
        path = "${config.users.users.${username}.home}/Sources/github.com/ivankovnatsky/nix-config";
        remote = "origin";
        remoteUrl = "https://github.com/ivankovnatsky/nix-config.git";
        branch = "main";
      }
      {
        path = "${config.users.users.${username}.home}/Notes";
        remote = "origin";
        remoteUrl = "https://forgejo.@domain@/@username@/notes.git";
        branch = "main";
        autoStage = true;
      }
      {
        path = "${config.users.users.${username}.home}/.openclaw/workspace";
        remote = "origin";
        remoteUrl = "https://forgejo.@domain@/@username@/workspace.git";
        branch = "main";
      }
      {
        path = "/storage/data";
        remote = "origin";
        remoteUrl = "https://forgejo.@domain@/@username@/data.git";
        branch = "main";
      }
    ];
  };
}
