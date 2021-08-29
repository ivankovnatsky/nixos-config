{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ arandr maim xclip xorg.xev ];
}
