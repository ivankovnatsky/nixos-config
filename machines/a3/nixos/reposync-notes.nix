{ config, username, ... }:
{
  local.services.reposync.repositories = [
    {
      path = "${config.users.users.${username}.home}/Notes";
      remote = "origin";
      remoteUrl = "https://forgejo.@domain@/swedishunhorned/notes.git";
      branch = "main";
    }
  ];
}
