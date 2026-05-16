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
      path = "${config.users.users.${username}.home}/NotesGit";
      remote = "origin";
      remoteUrl = "https://forgejo.@domain@/@username@/notes.git";
      branch = "main";
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
}
