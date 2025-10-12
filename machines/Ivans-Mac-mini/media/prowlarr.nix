{
  config,
  pkgs,
  ...
}:

# Indexers configured:
# * toloka.to (REMOVED - no longer available upstream)
# * EZTV
# * TheRARBG (REMOVED - RARBG shut down permanently in May 2023)
# * LimeTorrents
# * The Pirate Bay
#
# Manual configuration:
# * Get API Key:
#   * Settings → General → Security → API Key (save to modules/secrets/default.nix)
# * Add indexers via Settings → Indexers
# * Add apps via Settings → Apps:
#   * Radarr: localhost:7878, get API key from Radarr → Settings → General
#   * Sonarr: localhost:8989, get API key from Sonarr → Settings → General
# * Sync indexers to apps via Settings → Apps → Sync App Indexers
#
# References:
# * https://www.reddit.com/r/radarr/comments/1dbx8u2/comment/l7u08gc/
# * https://www.reddit.com/r/trackers/comments/1h4l0sa/comment/lzzkwaj/

let
  volumePath = "/Volumes/Storage";
  dataDir = "${volumePath}/Data/.prowlarr";
in
{
  launchd.user.agents.prowlarr = {
    serviceConfig = {
      Label = "com.ivankovnatsky.prowlarr";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/agents/log/launchd/prowlarr.log";
      StandardErrorPath = "/tmp/agents/log/launchd/prowlarr.error.log";
      ThrottleInterval = 10;
    };

    command =
      let
        prowlarrScript = pkgs.writeShellScriptBin "prowlarr-starter" ''
          /bin/wait4path "${volumePath}"

          mkdir -p ${dataDir}

          exec ${pkgs.prowlarr}/bin/Prowlarr -nobrowser -data=${dataDir}
        '';
      in
      "${prowlarrScript}/bin/prowlarr-starter";
  };
}
