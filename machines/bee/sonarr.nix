{
  # NOTE: For proper download handling with Transmission:
  # 1. In Sonarr UI, enable "Remove Completed" in the Transmission download client settings
  # 2. Transmission must be configured to pause/stop torrents after meeting ratio/time goals
  #    (ratio-limit-enabled = true and/or seed-time-limit-enabled = true)
  # 3. Sonarr will only remove downloads from Transmission when they are paused/stopped

  # References and howtos:
  # * https://www.reddit.com/r/sonarr/comments/10eg5fw/best_method_to_fix_incorrect_episode_nameepisode/?rdt=54609
  # * https://forums.sonarr.tv/t/stop-early-file-from-downloading/38285/2
  # * https://www.redditmedia.com/r/sonarr/comments/1i82r5l/stop_lnk_files_from_downloading/
  #
  # Enable Sonarr
  # Manual configurations:
  # * Disable analytics
  # * In every indexer set fail downloads:
  #   * Executables
  #   * Potentially dangerous
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
    "d /storage/Data/media/tv 0775 sonarr media -" # Main TV shows directory
    "d /storage/Data/media/downloads/tv-sonarr 0775 transmission media -" # Where Transmission puts downloaded TV shows
  ];

  # Ensure groups exist and users have correct permissions
  users.groups.media.members = [
    "sonarr"
    "transmission"
    "plex"
  ];

  # Add supplementary groups to Sonarr service
  systemd.services.sonarr.serviceConfig = {
    SupplementaryGroups = [ "media" ];
    UMask = "0002";
  };
}
