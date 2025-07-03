{ pkgs, ... }:

{
  users.users."Ivan.Kovnatskyi" = {
    shell = pkgs.fish;
    ignoreShellProgramCheck = true;
  };
}
