{ config
, pkgs
, ...
}:

let
  dataDir = "${config.flags.miniStoragePath}/Media/Podservice";
  audioDir = "${dataDir}/audio";
  metadataDir = "${dataDir}/metadata";
  urlsFile = "${dataDir}/urls.txt";

  configFile = pkgs.writeText "podservice-config.yaml" (builtins.toJSON {
    server = {
      port = 8083;
      host = config.flags.miniIp;
      base_url = "https://podservice.@EXTERNAL_DOMAIN@";
    };
    podcast = {
      title = "YouTube Podcast";
      description = "Converted YouTube videos as podcast episodes";
      author = "Pod Service";
      language = "en-us";
      category = "Technology";
    };
    storage = {
      data_dir = dataDir;
      audio_dir = audioDir;
    };
    watch = {
      enabled = true;
      file = urlsFile;
    };
    log_level = "INFO";
  });

  # Substitute external domain at runtime
  runtimeConfigFile = pkgs.writeShellScript "podservice-config-gen" ''
    EXTERNAL_DOMAIN=$(cat ${config.sops.secrets.external-domain.path})
    ${pkgs.gnused}/bin/sed "s/@EXTERNAL_DOMAIN@/$EXTERNAL_DOMAIN/g" ${configFile}
  '';
in
{
  local.launchd.services.podservice = {
    enable = true;
    waitForPath = config.flags.miniStoragePath;
    dataDir = dataDir;
    extraDirs = [
      audioDir
      metadataDir
    ];
    preStart = ''
      # Generate runtime config with secrets
      ${runtimeConfigFile} > ${dataDir}/config.yaml
    '';
    command = ''
      ${pkgs.podservice}/bin/podservice serve --config=${dataDir}/config.yaml
    '';
    environment = {
      PATH = "${pkgs.coreutils}/bin:${pkgs.ffmpeg}/bin:${pkgs.yt-dlp}/bin";
    };
  };
}
