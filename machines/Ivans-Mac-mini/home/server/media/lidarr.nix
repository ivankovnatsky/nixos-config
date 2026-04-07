{
  config,
  pkgs,
  ...
}:

# Initial onboarding:
#
# 1. On first launch, Lidarr prompts for authentication setup:
#    * Authentication Method: Forms (Login Page)
#    * Authentication Required: Enabled
#    * Set username and password, then Save
#
# Manual configuration:
#
# * Get API Key and save to sops (secrets/default.yaml arr.lidarr.apiKey):
#   * Settings -> General -> Security -> API Key
# * Setup transmission as download client:
#   * Settings
#   * Download Clients
#   * Add Transmission
#   * Host: localhost, Port: 9091
#   * Username/Password: from transmission config
#   * Category: lidarr
#   * Save
# * Disable analytics:
#   * Settings
#   * General
#   * Save Changes
# * Configure music library:
#   * Music -> Add Root Folder -> /Volumes/Storage/Data/Music

let
  dataDir = "${config.flags.externalStoragePath}/.lidarr";
  musicDir = "${config.flags.externalStoragePath}/Music";
  downloadsDir = "${config.flags.externalStoragePath}/Media/Downloads/Lidarr";
in
{
  local.launchd.services.lidarr = {
    enable = true;
    waitForPath = config.flags.externalStoragePath;
    inherit dataDir;
    extraDirs = [
      musicDir
      downloadsDir
    ];
    preStart = ''
      if [ -f "${dataDir}/config.xml" ]; then
        ${pkgs.gnused}/bin/sed -i 's|<BindAddress>[^<]*</BindAddress>|<BindAddress>*</BindAddress>|' "${dataDir}/config.xml"
      fi
    '';
    command = "${pkgs.lidarr}/bin/Lidarr -nobrowser -data=${dataDir}";
  };
}
