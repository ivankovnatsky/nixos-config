{
  # Initial Setup (manual, one-time):
  # 1. Access the web UI at https://jellyfin.{externalDomain}
  # 2. Create your root user during the initial setup process
  # 3. Generate API key: Administration → Dashboard → Advanced → API Keys → New API Key
  # 4. Save the key in modules/secrets/default.nix under secrets.jellyfin.apiKey
  #
  # After initial setup, jellyfin-mgmt will declaratively manage libraries

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
