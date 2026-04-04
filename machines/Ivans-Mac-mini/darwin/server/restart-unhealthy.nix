{ pkgs, ... }:

{
  # Restart our unhealthy daemons after boot (gives them time to settle)
  local.launchd.services.restart-unhealthy-daemons = {
    enable = true;
    command = "/bin/bash -c 'sleep 2m && ${pkgs.launchd-mgmt}/bin/launchd-mgmt -f ivankovnatsky restart --unhealthy -t daemons'";
    waitForSecrets = false;
    keepAlive = false;
  };
}
