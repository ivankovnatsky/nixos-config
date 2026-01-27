{
  local.launchd.services.xattr-pin-notes = {
    enable = true;
    type = "user-agent";
    runAtLoad = true;
    keepAlive = false;
    command = "/bin/bash -c '/usr/bin/xattr -w \"com.apple.fileprovider.pinned#PX\" 1 \"$HOME/Library/Mobile Documents/com~apple~CloudDocs/Data/Notes\"'";
  };
}
