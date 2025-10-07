{
  # NOTE: Manual Jellyfin configuration is required after installation:
  # 1. Access the web UI at https://jellyfin-mini.{externalDomain}
  # 2. Create your root user during the initial setup process
  # 3. Add libraries for your media, pointing to appropriate directories
  #
  # Libraries configured manually via UI:
  # - Movies: /mnt/mac/Volumes/Storage/Data/media/movies
  # - Shows:  /mnt/mac/Volumes/Storage/Data/media/tv
  #
  # The /mnt/mac/Volumes/Storage path is OrbStack's automatic mount of macOS /Volumes/Storage
  # Media is synced from bee's /storage via Syncthing to mini's /Volumes/Storage

  # TODO: Can we configure through code?

  # Enable Jellyfin Media Server
  services.jellyfin = {
    enable = true;
    openFirewall = true;

    # Use default user/group from the module
    user = "jellyfin";
    group = "jellyfin";

    # Configuration directories
    dataDir = "/var/lib/jellyfin";
  };

  # Ensure Jellyfin can access media directories
  users.users.jellyfin.extraGroups = [ "media" ];

  # Make sure the media group exists
  users.groups.media = { };
}
