{ pkgs, config, username, lib, ... }:
{
  users.knownUsers = [ username ];
  users.users.${username}.shell = lib.mkIf config.flags.enableFishShell pkgs.fish;
}
