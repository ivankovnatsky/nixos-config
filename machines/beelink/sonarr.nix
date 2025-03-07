{
  # Enable Sonarr
  services.sonarr = {
    enable = true;
    openFirewall = true;

    # Use default values from the module
    user = "sonarr";
    group = "sonarr";
    dataDir = "/var/lib/sonarr/.config/NzbDrone";
  };

  # Create media directories with correct permissions
  systemd.tmpfiles.rules = [
    "d /media/tv 0775 sonarr media -"  # Main TV shows directory
    "d /media/downloads/movies/tv-sonarr 0775 transmission media -"  # Where Transmission puts downloaded TV shows
  ];

  # Ensure groups exist and users have correct permissions
  users.groups.media.members = [ "sonarr" "transmission" "plex" ];

  # Add supplementary groups to Sonarr service
  systemd.services.sonarr.serviceConfig = {
    SupplementaryGroups = [ "media" ];
    UMask = "0002";
  };
}
