{ config, username, ... }:
{
  local.services.reposync.repositories = [
    {
      path = "${config.flags.externalStoragePath}/Sources/github.com/ivankovnatsky/nix-config";
      remote = "origin";
      remoteUrl = "https://github.com/ivankovnatsky/nix-config.git";
      branch = "main";
    }
  ];
}
