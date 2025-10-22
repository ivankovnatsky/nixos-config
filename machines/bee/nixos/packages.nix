{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    direnv
  ];

  programs.direnv = {
    enable = true;
    silent = true;
  };
}
