{ config, ... }:
{
  flags = {
    enableFishShell = true;
    purpose = "home";
    editor = "nvim";
    darkMode = true;
    obsidian.vaultPaths = [ "${config.home.homeDirectory}/Notes" ];
  };
}
