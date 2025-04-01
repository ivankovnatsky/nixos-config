{
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

  # Create media directories with correct permissions if they don't exist
  systemd.tmpfiles.rules = [
    "d /storage/media/movies 0775 plex media -"
  ];
}
