{ config, lib, pkgs, ... }:

{
  programs.nix-index = {
    enable = true;
    enableFishIntegration = true;
  };
}
