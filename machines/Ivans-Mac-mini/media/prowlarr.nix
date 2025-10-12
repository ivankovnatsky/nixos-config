{
  config,
  pkgs,
  ...
}:

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
