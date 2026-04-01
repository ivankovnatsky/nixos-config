# Requires: System Settings > Privacy & Security > Accessibility > allow Terminal
{ pkgs, ... }:

{
  local.launchd.services.ensure-spaces = {
    enable = true;
    type = "user-agent";
    command = "${pkgs.settings}/bin/settings spaces ensure --count 16";
    runAtLoad = true;
    keepAlive = false;
  };
}
