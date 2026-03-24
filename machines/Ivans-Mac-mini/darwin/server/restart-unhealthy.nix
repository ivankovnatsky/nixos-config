{ pkgs, ... }:

{
  # Restart our unhealthy agents after boot (gives them time to settle)
  local.launchd.services.restart-unhealthy-agents = {
    enable = true;
    type = "user-agent";
    command = "/bin/bash -c 'sleep 2m && ${pkgs.launchd-mgmt}/bin/launchd-mgmt -f ivankovnatsky restart --unhealthy -t agents'";
    waitForSecrets = false;
    keepAlive = false;
  };

  # Restart our unhealthy daemons after boot (gives them time to settle)
  local.launchd.services.restart-unhealthy-daemons = {
    enable = true;
    type = "daemon";
    command = "/bin/bash -c 'sleep 2m && ${pkgs.launchd-mgmt}/bin/launchd-mgmt -f ivankovnatsky restart --unhealthy -t daemons'";
    waitForSecrets = false;
    keepAlive = false;
  };
}
