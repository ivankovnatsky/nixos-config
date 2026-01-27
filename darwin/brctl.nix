{
  local.launchd.services.brctl-download-notes = {
    enable = true;
    type = "user-agent";
    runAtLoad = true;
    keepAlive = false;
    command = "/bin/bash -c '/usr/bin/find \"$HOME/Library/Mobile Documents/com~apple~CloudDocs/Data/Notes\" -exec /usr/bin/brctl download {} \\;'";

    extraServiceConfig = {
      StartCalendarInterval = {
        Minute = 0;
      };
    };
  };
}
