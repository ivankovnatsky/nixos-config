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
  volumePath = "/Volumes/Storage";
  dataDir = "${volumePath}/Data/.radarr";
  moviesDir = "${volumePath}/Data/Media/Movies";
  downloadsDir = "${volumePath}/Data/Media/Downloads/Radarr";
in
{
  launchd.user.agents.radarr = {
    serviceConfig = {
      Label = "com.ivankovnatsky.radarr";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/agents/log/launchd/radarr.log";
      StandardErrorPath = "/tmp/agents/log/launchd/radarr.error.log";
      ThrottleInterval = 10;
    };

    command =
      let
        radarrScript = pkgs.writeShellScriptBin "radarr-starter" ''
          /bin/wait4path "${volumePath}"

          mkdir -p ${dataDir}
          mkdir -p ${moviesDir}
          mkdir -p ${downloadsDir}

          exec ${pkgs.radarr}/bin/Radarr -nobrowser -data=${dataDir}
        '';
      in
      "${radarrScript}/bin/radarr-starter";
  };
}
