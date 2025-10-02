{
  config,
  pkgs,
  ...
}:

{
  launchd.agents = {
    "prevent-sleep" = {
      enable = true;
      config = {
        Label = "prevent-sleep";
        ProgramArguments = [
          "/etc/profiles/per-user/${config.home.username}/bin/prevent-sleep"
        ];
        RunAtLoad = true;
        KeepAlive = true;

        StandardOutPath = "/tmp/agents/log/launchd/prevent-sleep.log";
        StandardErrorPath = "/tmp/agents/log/launchd/prevent-sleep.error.log";

        EnvironmentVariables = {
          HOME = config.home.homeDirectory;
        };
      };
    };
  };
}
