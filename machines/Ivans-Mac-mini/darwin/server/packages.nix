{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    gnumake # To avoid installing Developer Tools
    tmux
    git
  ];
}
