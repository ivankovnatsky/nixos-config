{ config, ... }:

{
  local.unison.syncs.notes = {
    pathA = "${config.home.homeDirectory}/Notes";
    pathB = "${config.home.homeDirectory}/NotesGit";
    ignore = [
      "Path .rumdl_cache"
      "Path .git"
      "Path .claude"
      "Path .obsidian/workspace.json"
      "Path .obsidian/workspace-mobile.json"
    ];
    interval = 60 * 5;
  };
}
