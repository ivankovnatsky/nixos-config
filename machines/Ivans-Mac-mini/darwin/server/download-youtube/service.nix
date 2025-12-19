{
  config,
  pkgs,
  ...
}:

let
  dataDir = "${config.flags.miniStoragePath}/Media/Youtube";
in
{
  local.launchd.services.download-youtube = {
    enable = true;
    waitForPath = config.flags.miniStoragePath;
    dataDir = dataDir;
    command = ''
      ${pkgs.download-youtube}/bin/download-youtube daemon \
        --host ${config.flags.miniIp} \
        --port 8085 \
        --output-dir ${dataDir}
    '';
    environment = {
      PATH = "${pkgs.coreutils}/bin:${pkgs.ffmpeg}/bin:${pkgs.nixpkgs-darwin-master.yt-dlp}/bin";
    };
  };
}
