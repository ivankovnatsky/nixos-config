{ pkgs, ... }:

{
  users.users.ivan = {
    shell = pkgs.fish;
  };

  programs.fish.enable = true;
  programs.starship.enable = true;

  environment.systemPackages = with pkgs; [
    fish
    starship
  ];
}
