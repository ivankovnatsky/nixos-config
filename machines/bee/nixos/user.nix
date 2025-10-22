{ pkgs, ... }:

{
  users.users.ivan = {
    shell = pkgs.fish;
  };

  programs.fish.enable = true;
}
