{
  config,
  ...
}:

{
  launchd.agents = {
    "backup-home" = {
      enable = true;
      config = {
        ProgramArguments = [
          "/etc/profiles/per-user/${config.home.username}/bin/backup-home"
        ];
        StartCalendarInterval = [
          {
            Hour = 17;
            Minute = 0;
            Weekday = 1; # Monday
          }
          {
            Hour = 17;
            Minute = 0;
            Weekday = 2; # Tuesday
          }
          {
            Hour = 17;
            Minute = 0;
            Weekday = 3; # Wednesday
          }
          {
            Hour = 17;
            Minute = 0;
            Weekday = 4; # Thursday
          }
          {
            Hour = 17;
            Minute = 0;
            Weekday = 5; # Friday
          }
        ];

        StandardOutPath = "/tmp/log/launchd/backup-home.out.log";
        StandardErrorPath = "/tmp/log/launchd/backup-home.err.log";
        KeepAlive = false;
        RunAtLoad = false;

        EnvironmentVariables = {
          HOME = config.home.homeDirectory;
        };
      };
    };
  };
}
