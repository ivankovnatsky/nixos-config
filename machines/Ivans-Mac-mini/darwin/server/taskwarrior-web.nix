{ config, pkgs, ... }:

{
  local.launchd.services.taskwarrior-web = {
    enable = true;
    type = "user-agent";
    environment = {
      TWK_SERVER_ADDR = config.flags.machineBindAddress;
      TWK_SERVER_PORT = "8087";
      PATH = "${pkgs.taskwarrior3}/bin";
    };
    command = ''
      ${pkgs.taskwarrior-web}/bin/taskwarrior-web
    '';
  };
}
