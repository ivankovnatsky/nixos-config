{
  config,
  pkgs,
  ...
}:

let
  volumePath = "/Volumes/Storage";
  dataDir = "${volumePath}/Data/.radarr";
  moviesDir = "${volumePath}/Data/media/movies";
  downloadsDir = "${volumePath}/Data/media/downloads/radarr";
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
