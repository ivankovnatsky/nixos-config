{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    btop
    gnumake
  ];
}
