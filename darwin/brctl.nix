{
  local.launchd.services.brctl-download-notes = {
    enable = true;
    type = "user-agent";
    runAtLoad = false;
    keepAlive = false;
    command = "/usr/bin/brctl download ~/Library/Mobile\\ Documents/com~apple~CloudDocs/Data/Notes";

    extraServiceConfig = {
      StartCalendarInterval = {
        Minute = 0;
      };
    };
  };
}
