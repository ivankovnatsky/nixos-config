{ pkgs, ... }:

{
  users.users.ivan = {
    shell = pkgs.fish;
    linger = true;
  };
  programs.fish.enable = true;
}
