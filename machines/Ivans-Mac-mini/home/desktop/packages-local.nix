{ pkgs, ... }:
{
  home.packages = with pkgs; [
    launchd-mgmt
  ];
}
