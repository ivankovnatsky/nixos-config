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
        ignore = [
          "Path .git"
          "Path .obsidian/app.json"
          "Path .obsidian/workspace.json"
          "Path .obsidian/workspace-mobile.json"
        ];
      };
    };
  };
}
