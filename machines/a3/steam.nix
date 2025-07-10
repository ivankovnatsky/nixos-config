{ config, lib, pkgs, ... }:

{
  # Enable Steam
  programs.steam = {
    enable = true;
  };
}