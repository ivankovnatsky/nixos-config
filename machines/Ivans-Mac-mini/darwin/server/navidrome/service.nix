{ config, pkgs, ... }:

let
  dataDir = "${config.flags.externalStoragePath}/.navidrome";
  musicDir = "${config.flags.externalStoragePath}/Music";
in
{
  local.launchd.services.navidrome = {
    enable = true;
    waitForPath = config.flags.externalStoragePath;
    inherit dataDir;
    extraDirs = [
      musicDir
    ];
    command = ''
      ${pkgs.navidrome}/bin/navidrome \
        --datafolder "${dataDir}" \
        --musicfolder "${musicDir}" \
        --address ${config.flags.machineBindAddress} \
        --port 4533
    '';
    environment = {
      # Enable transcoding via ffmpeg (bundled with nixpkgs navidrome)
      ND_ENABLETRANSCODINGCONFIG = "true";
      ND_SCANNER_SCHEDULE = "@every 15m";
    };
  };
}
