{
  # NOTE: For proper download handling with Transmission:
  # 1. In Sonarr UI, enable "Remove Completed" in the Transmission download client settings
  # 2. Transmission must be configured to pause/stop torrents after meeting ratio/time goals
  #    (ratio-limit-enabled = true and/or seed-time-limit-enabled = true)
  # 3. Sonarr will only remove downloads from Transmission when they are paused/stopped

  # References and howtos:
  # * TRaSH Guides: https://trash-guides.info/
  # * Remote Path Mapping: https://trash-guides.info/Sonarr/Sonarr-remote-path-mapping/
  # * https://www.reddit.com/r/sonarr/comments/10eg5fw/best_method_to_fix_incorrect_episode_nameepisode/?rdt=54609
  # * https://forums.sonarr.tv/t/stop-early-file-from-downloading/38285/2
  # * https://www.redditmedia.com/r/sonarr/comments/1i82r5l/stop_lnk_files_from_downloading/
  #
  # Enable Sonarr
  # Manual configurations:
  # * Get API Key:
  #   * Settings → General → Security → API Key (save to modules/secrets/default.nix)
  # * Disable analytics
  # * Setup transmission password:
  #   * Settings → Download Clients → Add Transmission
  #   * Host: localhost, Port: 9091
  #   * Username/Password: from transmission config
  #   * Category: tv-sonarr
  #   * Enable "Remove Completed"
  #   * Save
  # * In every indexer set fail downloads:
  #   * Executables
  #   * Potentially dangerous
  # * Configure media library:
  #   * Series → Add Root Folder → /var/lib/sonarr/media/tv
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
    # Base media directory owned by sonarr
    "d /var/lib/sonarr/media 0755 sonarr sonarr - -"

    # Sonarr-specific directories
    "d /var/lib/sonarr/media/tv 2775 sonarr sonarr -" # Main TV shows directory with setgid

    # Transmission shared directories
    "d /var/lib/transmission/media 0755 transmission media - -" # Base transmission media directory
    "Z /var/lib/transmission/media/downloads 2775 transmission media - -" # Fix ownership on existing downloads directory
    "d /var/lib/transmission/media/downloads/tv-sonarr 0775 transmission media -" # Where Transmission puts downloaded TV shows

    # Set proper default ACLs for the Sonarr downloads directory
    # This overrides the restrictive default ACLs inherited from parent directories
    "A+ /var/lib/transmission/media/downloads/tv-sonarr - - - - default:user::rwx,default:group::rwx,default:other::r-x"

    # Set proper default ACLs for the TV shows directory
    "A+ /var/lib/sonarr/media/tv - - - - default:user::rwx,default:group::rwx,default:other::r-x"
  ];

  # Ensure groups exist and users have correct permissions
  users.groups.media.members = [
    "sonarr"
    "transmission"
    "ivan"
  ];

  # Add ivan to sonarr group for syncthing access to existing directories
  users.users.ivan.extraGroups = [ "sonarr" ];

  # Add supplementary groups to Sonarr service
  systemd.services.sonarr.serviceConfig = {
    SupplementaryGroups = [ "media" ];
    UMask = "0002";
  };
}
