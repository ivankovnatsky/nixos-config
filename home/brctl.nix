{
  local.launchd.services.brctl-download-notes = {
    enable = true;
    runAtLoad = true;
    keepAlive = false;
    command = "/bin/bash -c '/usr/bin/find \"$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Notes\" -exec /usr/bin/brctl download {} \\;'";

    extraServiceConfig = {
      StartCalendarInterval = {
        Minute = 0;
      };
    };
  };
}
