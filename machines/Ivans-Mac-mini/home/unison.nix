{ config, ... }:

{
  local.unison.syncs.notes = {
    pathA = "${config.flags.externalStoragePath}/Notes";
    pathB = "${config.home.homeDirectory}/Library/Mobile Documents/iCloud~md~obsidian/Documents/Notes";
    ignore = [
      "Path .git"
      "Path .obsidian/app.json"
    ];
    interval = 60 * 5;
    waitForPath = config.flags.externalStoragePath;
  };
}
