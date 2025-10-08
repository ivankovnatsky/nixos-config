{ config, ... }:
{
  # NOTE: Initial manual Audiobookshelf configuration required:
  # 1. Access web UI at https://audiobookshelf-mini.${config.secrets.externalDomain}
  # 2. Create root user during initial setup
  # 3. Copy API token: Settings → Users → root → API token
  # 4. Add token to modules/secrets/default.nix (secrets.audiobookshelf.apiToken)
  # 5. Libraries are managed declaratively via abs-mgmt (see mgmt.nix)

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
