{
  config,
  pkgs,
  username,
  ...
}:

{
  local.launchd.services.taskweb = {
    enable = true;
    type = "user-agent";
    environment = {
      TASKDATA = "${config.users.users.${username}.home}/.task";
    };
    command = ''
      ${pkgs.taskweb}/bin/taskweb serve --host ${config.flags.machineBindAddress} --port 8088
    '';
  };
}
