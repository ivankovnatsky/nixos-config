{
  # NOTE: Manual Jellyfin configuration is required after installation:
  # 1. Access the web UI at https://jellyfin.{externalDomain}
  # 2. Create your root user during the initial setup process
  # 3. Add libraries for your media, pointing to appropriate directories in /storage/media

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

  # Jellyfin will access existing media directories
  # No need to create directories as they're managed by radarr and sonarr

  # Make sure the media group exists
  users.groups.media = {};
}
