{ config
, pkgs
, ...
}:
let
  preventSleepWrapper = pkgs.writeScriptBin "prevent-sleep-wrapper" ''
    #!${pkgs.bash}/bin/bash

    # Check if caffeinate is already running with our specific flags
    if /usr/bin/pgrep -f "caffeinate.*-d.*-i.*-m.*-s.*-t.*43200" > /dev/null; then
        echo "prevent-sleep is already running, skipping..."
        exit 0
    fi

    # Start prevent-sleep
    exec /etc/profiles/per-user/${config.home.username}/bin/prevent-sleep
  '';
in
{
  launchd.agents = {
    "prevent-sleep" = {
      enable = true;
      config = {
        Label = "prevent-sleep";
        ProgramArguments = [
          "${preventSleepWrapper}/bin/prevent-sleep-wrapper"
        ];
        StartCalendarInterval =
          builtins.concatMap
            (hour: [
              {
                Hour = hour;
                Minute = 0;
                Weekday = 1;
              }
              {
                Hour = hour;
                Minute = 0;
                Weekday = 2;
              }
              {
                Hour = hour;
                Minute = 0;
                Weekday = 3;
              }
              {
                Hour = hour;
                Minute = 0;
                Weekday = 4;
              }
              {
                Hour = hour;
                Minute = 0;
                Weekday = 5;
              }
            ])
            [
              9
              10
              11
              12
              13
              14
              15
              16
              17
            ];
        RunAtLoad = false;
        KeepAlive = false;

        StandardOutPath = "/tmp/agents/log/launchd/prevent-sleep.log";
        StandardErrorPath = "/tmp/agents/log/launchd/prevent-sleep.error.log";

        EnvironmentVariables = {
          HOME = config.home.homeDirectory;
        };
      };
    };
  };
}
