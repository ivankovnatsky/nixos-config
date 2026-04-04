{
  config,
  pkgs,
  ...
}:

let
  dataDir = "${config.flags.externalStoragePath}/.navidrome";
  musicDir = "${config.flags.externalStoragePath}/Music";
in
{
  sops.secrets.lastFm-api-key = {
    key = "lastFm/apiKey";
  };

  sops.secrets.lastFm-secret = {
    key = "lastFm/secret";
  };

  local.launchd.services.navidrome = {
    enable = true;
    waitForPath = config.flags.externalStoragePath;
    waitForSecrets = true;
    inherit dataDir;
    extraDirs = [
      musicDir
    ];
    preStart = ''
      export ND_LASTFM_APIKEY=$(cat ${config.sops.secrets.lastFm-api-key.path})
      export ND_LASTFM_SECRET=$(cat ${config.sops.secrets.lastFm-secret.path})
    '';
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
