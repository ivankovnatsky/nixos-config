{
  # Manual configuration:
  #
  # * Changed auth to Forms (Login Page) and change password for every *arr service:
  #   * Settings
  #   * General
  #   * Save Changes
  # * Setup transmission password for radarr:
  #   * Settings
  #   * Download Clients
  #   * Add Transmission
  #   * Host: localhost, Port: 9091
  #   * Username/Password: from transmission config
  #   * Category: radarr
  #   * Save
  # * Disable analytics:
  #   * Settings
  #   * General
  #   * Save Changes
  # * Configure media library:
  #   * Movies → Add Root Folder → /var/lib/radarr/media/movies

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
    "d /var/lib/radarr/media 0775 root media - -"

    # Radarr-specific directories
    "d /var/lib/radarr/media/movies 2775 radarr media -" # Main movies directory with setgid
    "d /var/lib/transmission/media/downloads 2775 transmission media -" # Where Transmission puts downloaded movies with setgid
    "d /var/lib/transmission/media/downloads/radarr 0775 transmission media -" # Radarr's download directory

    # Set proper default ACLs for the Radarr downloads directory
    # This overrides the restrictive default ACLs inherited from parent directories
    "A+ /var/lib/transmission/media/downloads/radarr - - - - default:user::rwx,default:group::rwx,default:other::r-x"

    # Set proper default ACLs for the movies directory
    "A+ /var/lib/radarr/media/movies - - - - default:user::rwx,default:group::rwx,default:other::r-x"
  ];

  # Ensure groups exist and users have correct permissions
  users.groups.media.members = [
    "radarr"
    "transmission"
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
