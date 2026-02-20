{ pkgs, ... }:

{
  users.users.ivan = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [ "wheel" ];
    linger = true;
  };
  programs.fish.enable = true;
}
