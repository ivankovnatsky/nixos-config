{
  config,
  pkgs,
  ...
}:

{
  local.launchd.services.taskweb = {
    enable = true;
    environment = {
      TASKDATA = "${config.home.homeDirectory}/.task";
    };
    command = ''
      ${pkgs.taskweb}/bin/taskweb serve --host ${config.flags.machineBindAddress} --port 8088
    '';
  };
}
