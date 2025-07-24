{
  config,
  lib,
  pkgs,
  ...
}:

let aichatPkg = pkgs.nixpkgs-master.aichat;

in
{
  home.packages = [ aichatPkg ];

  launchd.agents.aichat-server = {
    enable = true;
    config = {
      ProgramArguments = [
        "${aichatPkg}/bin/aichat"
        "--serve"
      ];

      KeepAlive = true;
      RunAtLoad = true;

      StandardOutPath = "/tmp/agents/log/launchd/aichat-server.log";
      StandardErrorPath = "/tmp/agents/log/launchd/aichat-server.error.log";

      EnvironmentVariables = {
        HOME = config.home.homeDirectory;
        PATH = lib.makeBinPath [ aichatPkg ];
      };
    };
  };
}
