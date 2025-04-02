{
  # Enable Radarr
  services.radarr = {
    enable = true;
    openFirewall = true;

    # Use default values from the module
    user = "radarr";
    group = "radarr";
    dataDir = "/var/lib/radarr/.config/Radarr";
  };

  # Create media directories with correct permissions
  systemd.tmpfiles.rules = [
    "d /storage/media/movies 0775 radarr media -" # Main movies directory
    "d /storage/media/downloads/movies 0775 transmission media -" # Where Transmission puts downloaded movies
    "d /storage/media/downloads/movies/radarr 0775 transmission media -" # Radarr's download directory
  ];

  # Ensure groups exist and users have correct permissions
  users.groups.media.members = [
    "radarr"
    "transmission"
    "plex"
  ];

  # Add supplementary groups to Radarr service
  systemd.services.radarr.serviceConfig = {
    SupplementaryGroups = [ "media" ];
    UMask = "0002";
  };
}
