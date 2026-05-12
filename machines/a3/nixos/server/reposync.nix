{ config, username, ... }:
{
  local.services.reposync.repositories = [
    {
      path = "${config.users.users.${username}.home}/Sources/github.com/ivankovnatsky/nix-config";
      remote = "origin";
      remoteUrl = "https://github.com/ivankovnatsky/nix-config.git";
      branch = "main";
    }
    {
      path = "${config.users.users.${username}.home}/Sources/github.com/openclaw/openclaw";
      remote = "origin";
      remoteUrl = "https://github.com/openclaw/openclaw.git";
      branch = "main";
      syncMode = "pull-only";
    }
    {
      path = "${config.users.users.${username}.home}/.openclaw/workspace";
      remote = "origin";
      remoteUrl = "https://forgejo.@domain@/@username@/workspace.git";
      branch = "main";
    }
  ];
}
