{ config, ... }:
{
  home.file."${config.xdg.configHome}/nvim/lua/auto-capitalize.lua".source = ./auto-capitalize.lua;

  programs.nixvim.extraConfigLua = ''
    require("auto-capitalize")
  '';
}
