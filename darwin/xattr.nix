let
  pinnedPaths = [
    "Library/Mobile Documents/com~apple~CloudDocs/Data/Notes"
    "Library/Mobile Documents/iCloud~com~mav~taskchamp"
    "Library/Mobile Documents/iCloud~md~obsidian"
  ];
  pathArgs = builtins.concatStringsSep " " (map (p: ''"$HOME/${p}"'') pinnedPaths);
in
{
  local.launchd.services.xattr-pin-notes = {
    enable = true;
    type = "user-agent";
    runAtLoad = true;
    keepAlive = false;
    command = "/bin/bash -c '/usr/bin/xattr -w \"com.apple.fileprovider.pinned#PX\" 1 ${pathArgs}'";
  };
}
