{ config, ... }:
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
  };

  local.services.reposync = {
    enable = true;
    alertStateFile = "${config.home.homeDirectory}/.local/state/reposync/alerts.json";
    domainFile = config.sops.secrets.external-domain.path;
    usernameFile = config.sops.secrets.forgejo-user-name.path;
    discordWebhookFile = config.sops.secrets.discord-webhook-reposync.path;

    repositories = [
      {
        name = "home";
        path = config.home.homeDirectory;
        remote = "origin";
        remoteUrl = "https://forgejo.@domain@/@username@/home.git";
        branch = "main";
        identity = forgejoIdentity;
      }
      {
        path = "${config.home.homeDirectory}/Sources/github.com/ivankovnatsky/nix-config";
        remote = "origin";
        remoteUrl = "https://github.com/ivankovnatsky/nix-config.git";
        branch = "main";
      }
      {
        path = "${config.home.homeDirectory}/Sources/github.com/ivankovnatsky/tools";
        remote = "origin";
        remoteUrl = "https://github.com/ivankovnatsky/tools.git";
        branch = "main";
      }
      {
        path = "${config.home.homeDirectory}/Sources/github.com/ivankovnatsky/podservice";
        remote = "origin";
        remoteUrl = "https://github.com/ivankovnatsky/podservice.git";
        branch = "main";
      }
      {
        path = "${config.home.homeDirectory}/Notes";
        remote = "origin";
        remoteUrl = "https://forgejo.@domain@/@username@/notes.git";
        branch = "main";
        autoStage = true;
        identity = forgejoIdentity;
      }
      {
        path = "/storage0/data";
        remote = "origin";
        remoteUrl = "https://forgejo.@domain@/@username@/data.git";
        branch = "main";
        identity = forgejoIdentity;
      }
      {
        path = "${config.home.homeDirectory}/Sources/@domain@/@username@/cv";
        remote = "origin";
        remoteUrl = "https://forgejo.@domain@/@username@/cv.git";
        branch = "main";
        identity = forgejoIdentity;
      }
    ];
  };
}
