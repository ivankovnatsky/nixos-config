{ config, ... }:

{
  local.unison.syncs.notes = {
    pathA = "${config.home.homeDirectory}/Library/Mobile Documents/iCloud~md~obsidian/Documents/Notes";
    pathB = "${config.home.homeDirectory}/Notes";
    ignore = [
      "Path .rumdl_cache"
      "Name .DS_Store"
      "Path .git"
      "Path .claude"
      "Path .obsidian/workspace.json"
      "Path .obsidian/workspace-mobile.json"
    ];
    interval = 60 * 1;
  };
}
