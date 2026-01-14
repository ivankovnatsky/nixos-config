# Requires: System Settings > Privacy & Security > Accessibility > allow Terminal
{ pkgs, ... }:

{
  local.launchd.services.close-zscaler = {
    enable = true;
    type = "user-agent";
    command = "${pkgs.settings}/bin/settings windows close Zscaler";
    preStart = ''
      # Wait for Zscaler to fully start and show its window
      sleep 90
    '';
    runAtLoad = true;
    keepAlive = false;
  };
}
