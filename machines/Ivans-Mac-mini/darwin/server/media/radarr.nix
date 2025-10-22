{
  config,
  pkgs,
  ...
}:

# Manual configuration:
#
# * Get API Key:
#   * Settings → General → Security → API Key (save to modules/secrets/default.nix)
# * Changed auth to Forms (Login Page) and change password for every *arr service:
#   * Settings
#   * General
#   * Save Changes
# * Setup transmission password for radarr:
#   * Settings
#   * Download Clients
#   * Add Transmission
#   * Host: localhost, Port: 9091
#   * Username/Password: from transmission config
#   * Category: radarr
#   * Save
# * Disable analytics:
#   * Settings
#   * General
#   * Save Changes
# * Configure media library:
#   * Movies → Add Root Folder → /Volumes/Storage/Data/Media/Movies

let
  dataDir = "${config.flags.miniStoragePath}/.radarr";
  moviesDir = "${config.flags.miniStoragePath}/Media/Movies";
  downloadsDir = "${config.flags.miniStoragePath}/Media/Downloads/Radarr";
in
{
  local.launchd.services.radarr = {
    enable = true;
    waitForPath = config.flags.miniStoragePath;
    dataDir = dataDir;
    extraDirs = [
      moviesDir
      downloadsDir
    ];
    command = "${pkgs.radarr}/bin/Radarr -nobrowser -data=${dataDir}";
  };
}
