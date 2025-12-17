{ pkgs, ... }:
{
  users.knownUsers = [ "ivan" ];
  users.users.ivan = {
    uid = 502;
    shell = pkgs.fish;
  };
}
