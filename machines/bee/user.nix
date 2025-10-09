{ pkgs, ... }:

{
  users.users.ivan = {
    shell = pkgs.bash;
  };
}
