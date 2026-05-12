{ config, ... }:
{
  flags = {
    enableFishShell = true;
    purpose = "home";
    editor = "nvim";
    darkMode = true;
    obsidian.vaultPaths = [ ];
    notesPath = "${config.home.homeDirectory}/iCloudDriveNotes";
  };
}
