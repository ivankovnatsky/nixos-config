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
    # Base media directory with group write permissions
    "d /storage/Data/media 0775 root media - -"

    # Radarr-specific directories
    "d /storage/Data/media/movies 2775 radarr media -" # Main movies directory with setgid
    "d /storage/Data/media/downloads 2775 transmission media -" # Where Transmission puts downloaded movies with setgid
    "d /storage/Data/media/downloads/radarr 0775 transmission media -" # Radarr's download directory

    # Set proper default ACLs for the Radarr downloads directory
    # This overrides the restrictive default ACLs inherited from parent directories
    "A+ /storage/Data/media/downloads/radarr - - - - default:user::rwx,default:group::rwx,default:other::r-x"

    # Set proper default ACLs for the movies directory
    "A+ /storage/Data/media/movies - - - - default:user::rwx,default:group::rwx,default:other::r-x"
  ];

  # Ensure groups exist and users have correct permissions
  users.groups.media.members = [
    "radarr"
    "transmission"
    "plex"
    "ivan"
  ];

  # Add ivan to radarr group for syncthing access to existing directories
  users.users.ivan.extraGroups = [ "radarr" ];

  # Add supplementary groups to Radarr service
  systemd.services.radarr.serviceConfig = {
    SupplementaryGroups = [ "media" ];
    UMask = "0002";
  };
}
