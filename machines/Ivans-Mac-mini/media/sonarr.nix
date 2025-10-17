{
  config,
  pkgs,
  ...
}:

# NOTE: For proper download handling with Transmission:
# 1. In Sonarr UI, enable "Remove Completed" in the Transmission download client settings
# 2. Transmission must be configured to pause/stop torrents after meeting ratio/time goals
#    (ratio-limit-enabled = true and/or seed-time-limit-enabled = true)
# 3. Sonarr will only remove downloads from Transmission when they are paused/stopped

# References and howtos:
# * TRaSH Guides: https://trash-guides.info/
# * Remote Path Mapping: https://trash-guides.info/Sonarr/Sonarr-remote-path-mapping/
# * https://www.reddit.com/r/sonarr/comments/10eg5fw/best_method_to_fix_incorrect_episode_nameepisode/?rdt=54609
# * https://forums.sonarr.tv/t/stop-early-file-from-downloading/38285/2
# * https://www.redditmedia.com/r/sonarr/comments/1i82r5l/stop_lnk_files_from_downloading/
#
# Manual configurations:
# * Get API Key:
#   * Settings → General → Security → API Key (save to modules/secrets/default.nix)
# * Disable analytics
# * Setup transmission password:
#   * Settings → Download Clients → Add Transmission
#   * Host: localhost, Port: 9091
#   * Username/Password: from transmission config
#   * Category: tv-sonarr
#   * Enable "Remove Completed"
#   * Save
# * In every indexer set fail downloads:
#   * Executables
#   * Potentially dangerous
# * Configure media library:
#   * Series → Add Root Folder → /Volumes/Storage/Data/Media/TV

let
  volumePath = "/Volumes/Storage";
  dataDir = "${volumePath}/Data/.sonarr";
  tvDir = "${volumePath}/Data/Media/TV";
  downloadsDir = "${volumePath}/Data/Media/Downloads/TV-Sonarr";
in
{
  launchd.user.agents.sonarr = {
    serviceConfig = {
      Label = "com.ivankovnatsky.sonarr";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/agents/log/launchd/sonarr.log";
      StandardErrorPath = "/tmp/agents/log/launchd/sonarr.error.log";
      ThrottleInterval = 10;
    };

    command =
      let
        sonarrScript = pkgs.writeShellScriptBin "sonarr-starter" ''
          /bin/wait4path "${volumePath}"

          mkdir -p ${dataDir}
          mkdir -p ${tvDir}
          mkdir -p ${downloadsDir}

          exec ${pkgs.sonarr}/bin/Sonarr -nobrowser -data=${dataDir}
        '';
      in
      "${sonarrScript}/bin/sonarr-starter";
  };
}
