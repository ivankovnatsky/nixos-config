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

      StandardOutPath = "/tmp/log/launchd/aichat-server.out.log";
      StandardErrorPath = "/tmp/log/launchd/aichat-server.err.log";

      EnvironmentVariables = {
        HOME = config.home.homeDirectory;
        PATH = lib.makeBinPath [ pkgs.aichat ];
      };
    };
  };
}
