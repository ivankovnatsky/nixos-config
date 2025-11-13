{ config
, lib
, pkgs
, ...
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

      StandardOutPath = "/tmp/agents/log/launchd/ollama.log";
      StandardErrorPath = "/tmp/agents/log/launchd/ollama.error.log";

      EnvironmentVariables = {
        HOME = config.home.homeDirectory;
        PATH = lib.makeBinPath [ pkgs.ollama ];
      };
    };
  };
}
