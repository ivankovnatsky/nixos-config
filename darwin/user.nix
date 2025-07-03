{ pkgs, ... }:

{
  users.users.ivan = {
    shell = pkgs.fish;
    ignoreShellProgramCheck = true;
  };
}
