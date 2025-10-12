{
  config,
  pkgs,
  ...
}:

let
  volumePath = "/Volumes/Storage";
  dataDir = "${volumePath}/Data/.sonarr";
  tvDir = "${volumePath}/Data/media/tv";
  downloadsDir = "${volumePath}/Data/media/downloads/tv-sonarr";
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
