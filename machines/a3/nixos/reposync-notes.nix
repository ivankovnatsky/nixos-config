{ config, username, ... }:
{
  local.services.reposync.repositories = [
    {
      path = "${config.users.users.${username}.home}/Notes";
      remote = "origin";
      remoteUrl = "https://forgejo.@domain@/@username@/notes.git";
      branch = "main";
    }
  ];
}
