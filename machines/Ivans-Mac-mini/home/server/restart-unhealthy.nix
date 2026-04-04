{ pkgs, ... }:

{
  # Restart our unhealthy agents after boot (gives them time to settle)
  local.launchd.services.restart-unhealthy-agents = {
    enable = true;
    command = "/bin/bash -c 'sleep 2m && ${pkgs.launchd-mgmt}/bin/launchd-mgmt -f ivankovnatsky restart --unhealthy -t agents'";
    waitForSecrets = false;
    keepAlive = false;
  };
}
