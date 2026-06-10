{ config, username, ... }:
let
  forgejoIdentity = {
    name = "@username@";
    email = "@username@@@domain@";
    signingKey = "@username@@@domain@";
  };
in
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
        identity = forgejoIdentity;
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
        identity = forgejoIdentity;
      }
      {
        path = "${config.users.users.${username}.home}/.openclaw/workspace";
        remote = "origin";
        remoteUrl = "https://forgejo.@domain@/@username@/workspace.git";
        branch = "main";
        identity = forgejoIdentity;
      }
      {
        path = "/storage/data";
        remote = "origin";
        remoteUrl = "https://forgejo.@domain@/@username@/data.git";
        branch = "main";
        identity = forgejoIdentity;
      }
    ];
  };
}
