{ config, username, ... }:
{
  local.services.reposync.repositories = [
    {
      path = "${config.users.users.${username}.home}/Sources/github.com/ivankovnatsky/nix-config";
      remote = "origin";
      remoteUrl = "https://github.com/ivankovnatsky/nix-config.git";
      branch = "main";
    }
  ];
}
