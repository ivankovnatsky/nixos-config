{ pkgs, ... }:
{
  # Additional system packages
  environment.systemPackages = with pkgs; [
    lsof
    tmux
  ];
}
