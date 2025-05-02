{ config, ... }:
{
  # NOTE: Manual Audiobookshelf configuration is required after installation:
  # 1. Access the web UI at https://audiobookshelf.{externalDomain}
  # 2. Create your root user during the initial setup process
  # 3. Add libraries for your audiobooks and podcasts, pointing to:
  #    - Podcasts library: /storage/Data/media/podcasts
  # 4. Configure metadata agents and other settings according to your preferences

  # Enable Audiobookshelf server
  services.audiobookshelf = {
    enable = true;
    openFirewall = true;

    # Use system-wide access instead of localhost only
    host = config.flags.beeIp;
    port = 8000;

    # Use default user/group from the module
    user = "audiobookshelf";
    group = "audiobookshelf";
    dataDir = "audiobookshelf";
  };

  # Ensure Audiobookshelf can access media directories
  users.users.audiobookshelf.extraGroups = [ "media" ];

  # Create media directories with correct permissions if they don't exist
  systemd.tmpfiles.rules = [
    "d /storage/Data/media/podcasts 0775 audiobookshelf media -"
  ];

  # Make sure the media group exists
  users.groups.media = { };
}
