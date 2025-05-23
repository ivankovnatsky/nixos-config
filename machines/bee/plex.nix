{
  # NOTE: Manual Plex configuration is required after installation:
  # 1. Create separate libraries for Movies and TV Shows in the Plex web interface
  # 2. For Movies library: use the 'Movies' type and point to /storage/Data/media/movies
  # 3. For TV Shows library: use the 'TV Shows' type and point to /storage/Data/media/tv
  # 4. Make sure to use the appropriate scanner for each library type:
  #    - Movies library should use 'Plex Movie' scanner
  #    - TV Shows library should use 'Plex TV Series' scanner

  # https://www.reddit.com/r/PleX/comments/ekk3yg/unable_to_add_media_to_plex_media_server/
  # Enable Plex Media Server
  services.plex = {
    enable = true;
    openFirewall = true;

    # Use default values from the module
    user = "plex";
    group = "plex";
    dataDir = "/var/lib/plex";

    # Enable hardware acceleration for transcoding
    accelerationDevices = [ "*" ];
  };

  # Ensure Plex can access media directories
  users.users.plex.extraGroups = [ "media" ];

  # Media directories are managed by radarr and sonarr
  # Plex access is provided through the media group
}
