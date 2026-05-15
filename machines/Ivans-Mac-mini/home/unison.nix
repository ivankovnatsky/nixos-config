{ config, ... }:

{
  local.unison.syncs.notes = {
    pathA = "${config.flags.externalStoragePath}/NotesGit";
    pathB = "${config.flags.externalStoragePath}/Notes";
    ignore = [
      "Path .git"
      "Path .claude"
      "Path .obsidian/workspace.json"
      "Path .obsidian/workspace-mobile.json"
    ];
    interval = 60 * 5;
    waitForPath = config.flags.externalStoragePath;
  };
}
