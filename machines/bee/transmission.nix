{
  # https://github.com/transmission/transmission/blob/main/docs/Editing-Configuration-Files.md
  services.transmission = {
    enable = true;
    openFirewall = true;
    openRPCPort = true;
    performanceNetParameters = true;

    settings = {
      # Web interface settings
      rpc-enabled = true;
      rpc-bind-address = "0.0.0.0"; # Listen on all interfaces
      rpc-port = 9091;
      rpc-host-whitelist-enabled = false;
      rpc-authentication-required = false;
      
      # Explicitly disable IP whitelist to allow proxy connections
      rpc-whitelist-enabled = false;
      # Include local network and Mac mini IP if whitelist is ever enabled
      rpc-whitelist = "192.168.*.*";

      # Download settings
      download-dir = "/storage/media/downloads/movies";
      incomplete-dir = "/storage/media/downloads/movies/.incomplete";
      incomplete-dir-enabled = true;
      watch-dir = "/storage/media/downloads/movies/watchdir";
      watch-dir-enabled = true;

      # Network settings
      peer-port = 51413;
      peer-port-random-on-start = false;
      port-forwarding-enabled = false;

      # Misc settings
      umask = 2; # 002 in decimal, results in 775 for dirs, 664 for files
      message-level = 2;
      cache-size-mb = 4;
      queue-stalled-enabled = true;
      queue-stalled-minutes = 30;
      
      # Seeding control (crucial for Sonarr cleanup)
      ratio-limit = 1.0; # Lowered from 2.0 to have quicker cleanup
      ratio-limit-enabled = true; # Enable ratio limit to make Sonarr able to remove completed downloads
      seed-time-limit = 30; # 30 minutes seed time (reduced from 60)
      seed-time-limit-enabled = true; # Enable seed time limit for Sonarr cleanup
      idle-seeding-limit = 30; # Additional 30 minutes idle time before pausing
      idle-seeding-limit-enabled = true; # Enable idle seeding limit as extra measure
      
      # Important: This ensures torrents actually stop when reaching limits
      script-torrent-done-enabled = true; # This is key for Sonarr cleanup

      # Speed limits
      speed-limit-down = 0;
      speed-limit-down-enabled = false;
      speed-limit-up = 0;
      speed-limit-up-enabled = false;

      # Peers and encryption
      encryption = 1; # 0 = disabled, 1 = enabled, 2 = required
      utp-enabled = true;
      dht-enabled = true;
      pex-enabled = true;
      lpd-enabled = false;
    };

    downloadDirPermissions = "775"; # Ensures correct permissions
  };

  # Ensure transmission can access media directories
  users.users.transmission.extraGroups = [
    "radarr"
    "plex"
  ];
}
