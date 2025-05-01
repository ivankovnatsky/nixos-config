{
  # Manual configuration:
  #
  # * Changed auth to Forms (Login Page) and change password for every *arr service:
  #   * Settings
  #   * General
  #   * Save Changes
  # * Setup transmission password for radarr and sonarr:
  #   * Settings
  #   * Download Clients
  #   * Save
  # * Disable analytics:
  #   * Settings
  #   * General
  #   * Save Changes

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
    "d /storage/media/downloads 0775 transmission media -" # Where Transmission puts downloaded movies
    "d /storage/media/downloads/radarr 0775 transmission media -" # Radarr's download directory
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
