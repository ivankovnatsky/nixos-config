{ pkgs, ... }:

{
  home.packages = with pkgs; [ nixd ];
  home.file.".config/zed/settings.json".source = ./settings.json;
}
