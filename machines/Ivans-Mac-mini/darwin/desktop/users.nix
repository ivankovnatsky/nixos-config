{ pkgs, ... }:
{
  users.knownUsers = [ "ivan" ];
  users.users.ivan = {
    uid = 501;
    shell = pkgs.fish;
  };
}
