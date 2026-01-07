{
  config,
  pkgs,
  ...
}:

let
  dataDir = "${config.flags.miniStoragePath}/Media/Youtube";

  python = pkgs.python3.withPackages (ps: [
    ps.flask
    ps.watchdog
  ]);

  youtube-daemon = pkgs.writeShellScriptBin "youtube-daemon" ''
    export PATH="${pkgs.giffer}/bin:$PATH"
    exec ${python}/bin/python ${./daemon.py} "$@"
  '';
in
{
  local.launchd.services.download-youtube = {
    enable = true;
    waitForPath = config.flags.miniStoragePath;
    dataDir = dataDir;
    command = ''
      ${youtube-daemon}/bin/youtube-daemon \
        --host ${config.flags.miniIp} \
        --port 8085 \
        --output-dir ${dataDir}
    '';
  };
}
