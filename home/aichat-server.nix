{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = [ pkgs.aichat ];

  launchd.agents.aichat-server = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.aichat}/bin/aichat"
        "--serve"
      ];

      KeepAlive = true;
      RunAtLoad = true;

      StandardOutPath = "/tmp/agents/log/launchd/aichat-server.log";
      StandardErrorPath = "/tmp/agents/log/launchd/aichat-server.error.log";

      EnvironmentVariables = {
        HOME = config.home.homeDirectory;
        PATH = lib.makeBinPath [ pkgs.aichat ];
      };
    };
  };
}
