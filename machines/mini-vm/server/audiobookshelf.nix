{ config, ... }:
{
  # NOTE: Manual Audiobookshelf configuration is required after installation:
  # 1. Access the web UI at https://audiobookshelf-mini.{externalDomain}
  # 2. Create your root user during the initial setup process
  # 3. Add libraries for your audiobooks and podcasts, pointing to:
  #    - Podcasts library: /mnt/mac/Volumes/Storage/Data/media/podcasts
  # 4. Configure metadata agents and other settings according to your preferences

  # Enable Audiobookshelf server
  services.audiobookshelf = {
    enable = true;
    openFirewall = true;

    # Bind to all interfaces for OrbStack NAT routing
    host = "0.0.0.0";
    port = 8000;

    # Use default user/group from the module
    user = "audiobookshelf";
    group = "audiobookshelf";
    dataDir = "audiobookshelf";
  };

  # Ensure Audiobookshelf can access media directories
  users.users.audiobookshelf.extraGroups = [ "media" ];

  # Make sure the media group exists
  users.groups.media = { };
}
