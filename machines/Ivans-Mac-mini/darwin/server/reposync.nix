{ config, ... }:
{
  local.services.reposync.repositories = [
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
    }
    {
      path = "${config.flags.externalStoragePath}/Notes";
      remote = "origin";
      remoteUrl = "https://forgejo.@domain@/@username@/notes.git";
      branch = "main";
    }
  ];
}
