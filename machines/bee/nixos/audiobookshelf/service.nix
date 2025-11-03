{ config, ... }:
{
  # NOTE: Manual Audiobookshelf configuration is required after installation:
  # 1. Access the web UI at https://audiobookshelf.{externalDomain}
  # 2. Create your root user during the initial setup process
  # 3. Add libraries for your audiobooks and podcasts, pointing to:
  #    - Podcasts library: /var/lib/audiobookshelf/media/podcasts
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

  # Disable SSRF filter for trusted local network environment
  # Allows podcast feeds from any source including private IPs
  # See: https://github.com/advplyr/audiobookshelf/issues/3742
  systemd.services.audiobookshelf = {
    environment = {
      DISABLE_SSRF_REQUEST_FILTER = "1";
    };

    # Wait for network to be fully online (DHCP IP assigned)
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };

  # Ensure Audiobookshelf can access media directories
  users.users.audiobookshelf.extraGroups = [ "media" ];

  # Create media directories with correct permissions if they don't exist
  systemd.tmpfiles.rules = [
    # Create podcasts directory with proper ownership
    "d /var/lib/audiobookshelf/media/podcasts 2775 audiobookshelf media -"

    # Set default ACLs for new files in the podcasts directory
    "A+ /var/lib/audiobookshelf/media/podcasts - - - - default:user::rwx,default:group::rwx,default:other::r-x"

    # Set ACLs for existing files in the podcasts directory
    "A+ /var/lib/audiobookshelf/media/podcasts - - - - user::rwx,group::rwx,other::r-x"
  ];

  # Make sure the media group exists
  users.groups.media = { };
}
