{
  services.transmission = {
    enable = true;
    openFirewall = true;
    openRPCPort = true;
    performanceNetParameters = true;

    settings = {
      # Web interface settings
      rpc-enabled = true;
      rpc-bind-address = "0.0.0.0";  # Listen on all interfaces
      rpc-port = 9091;
      rpc-host-whitelist-enabled = false;
      rpc-authentication-required = false;

      # Download settings
      download-dir = "/media/downloads/movies";
      incomplete-dir = "/media/downloads/movies/.incomplete";
      incomplete-dir-enabled = true;
      watch-dir = "/media/downloads/movies/watchdir";
      watch-dir-enabled = true;

      # Network settings
      peer-port = 51413;
      peer-port-random-on-start = false;
      port-forwarding-enabled = false;

      # Misc settings
      umask = 2;  # 002 in decimal, results in 775 for dirs, 664 for files
      message-level = 2;
      cache-size-mb = 4;
      queue-stalled-enabled = true;
      queue-stalled-minutes = 30;
      ratio-limit = 2.0;
      ratio-limit-enabled = false;
      
      # Speed limits
      speed-limit-down = 0;
      speed-limit-down-enabled = false;
      speed-limit-up = 0;
      speed-limit-up-enabled = false;
      
      # Peers and encryption
      encryption = 1;  # 0 = disabled, 1 = enabled, 2 = required
      utp-enabled = true;
      dht-enabled = true;
      pex-enabled = true;
      lpd-enabled = false;
    };

    downloadDirPermissions = "775";  # Ensures correct permissions
  };

  # Ensure transmission can access media directories
  users.users.transmission.extraGroups = [ "radarr" "plex" ];
}
