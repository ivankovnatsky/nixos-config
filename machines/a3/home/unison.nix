{ config, ... }:

{
  services.unison = {
    enable = true;
    pairs.icloud-notes = {
      roots = [
        "${config.home.homeDirectory}/Notes"
        "${config.home.homeDirectory}/iCloudDriveNotes"
      ];
      commandOptions = {
        perms = "0";
        ignore = [
          "Path .git"
          "Path .claude"
          "Path .obsidian/app.json"
          "Path .obsidian/workspace.json"
          "Path .obsidian/workspace-mobile.json"
        ];
      };
    };
  };
}
