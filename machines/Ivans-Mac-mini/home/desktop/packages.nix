{ pkgs, ... }:
{
  home.packages = with pkgs; [
    smctemp
    launchd-mgmt
  ];
}
