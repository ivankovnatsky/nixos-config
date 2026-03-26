# Requires: System Settings > Privacy & Security > Accessibility > allow Terminal
{ pkgs, ... }:

{
  local.launchd.services.close-mac-mouse-fix = {
    enable = true;
    type = "user-agent";
    command = "${pkgs.settings}/bin/settings windows close 'Mac Mouse Fix'";
    preStart = ''
      # Wait for Mac Mouse Fix to fully start and show its window
      sleep 90
    '';
    runAtLoad = true;
    keepAlive = false;
  };
}
