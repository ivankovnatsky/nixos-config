{ config, lib, pkgs, ... }:

{
  launchd.agents = {
    "backup-home" = {
      enable = true;
      config = {
        ProgramArguments = [
          "/etc/profiles/per-user/${config.home.username}/bin/backup-home-py"
        ];
        StartCalendarInterval = [
          {
            Hour = 17;
            Minute = 0;
            Weekday = 1;  # Monday
          }
          {
            Hour = 17;
            Minute = 0;
            Weekday = 2;  # Tuesday
          }
          {
            Hour = 17;
            Minute = 0;
            Weekday = 3;  # Wednesday
          }
          {
            Hour = 17;
            Minute = 0;
            Weekday = 4;  # Thursday
          }
          {
            Hour = 17;
            Minute = 0;
            Weekday = 5;  # Friday
          }
        ];
        StartOnMount = true;
        WatchPaths = [ "/" ];

        StandardOutPath = "/tmp/backup-home.out.log";
        StandardErrorPath = "/tmp/backup-home.err.log";
        KeepAlive = false;
        RunAtLoad = false;

        EnvironmentVariables = {
          HOME = config.home.homeDirectory;
        };
      };
    };
  };
}
