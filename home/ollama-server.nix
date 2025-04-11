{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = [ pkgs.ollama ];

  launchd.agents.ollama = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.ollama}/bin/ollama"
        "serve"
      ];

      KeepAlive = true;
      RunAtLoad = true;

      StandardOutPath = "/tmp/log/launchd/ollama.out.log";
      StandardErrorPath = "/tmp/log/launchd/ollama.err.log";

      EnvironmentVariables = {
        HOME = config.home.homeDirectory;
        PATH = lib.makeBinPath [ pkgs.ollama ];
      };
    };
  };
}
