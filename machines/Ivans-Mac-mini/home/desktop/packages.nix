{ pkgs, ... }:
{
  home.packages = with pkgs; [
    smctemp # Local overlay
    launchd-mgmt
  ];
}
