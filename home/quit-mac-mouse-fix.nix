# Requires: System Settings > Privacy & Security > Accessibility > allow Terminal
{ pkgs, ... }:

{
  local.launchd.services.quit-mac-mouse-fix = {
    enable = true;
    command = "${pkgs.settingsctl}/bin/settings windows quit --wait 10 'Mac Mouse Fix'";
    runAtLoad = true;
    keepAlive = false;
  };
}
