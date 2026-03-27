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
      path = "${config.users.users.${username}.home}/Notes";
      remote = "origin";
      remoteUrl = "https://forgejo.@domain@/forgejouser/notes.git";
      branch = "main";
    }
  ];
}
