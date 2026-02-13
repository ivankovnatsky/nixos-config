# To follow the feed in Apple Podcasts, use the "Podcast Follow" Shortcut.
# Manual steps are documented in Obsidian: Notes/Settings iphone and mac settings.
{
  config,
  pkgs,
  ...
}:

let
  dataDir = "${config.flags.externalStoragePath}/Media/Podservice";
  audioDir = "${dataDir}/Audio";
  metadataDir = "${dataDir}/Metadata";
  thumbnailsDir = "${dataDir}/Thumbnails";
  urlsFile = "${dataDir}/urls.txt";

  configFile = pkgs.writeText "podservice-config.yaml" (
    builtins.toJSON {
      server = {
        port = 8083;
        host = config.flags.miniIp;
        base_url = "http://${config.flags.miniIp}:8083";
      };
      podcast = {
        title = "Mini: My YouTube Podcast";
        description = "YouTube videos converted to podcast episodes";
        author = "Ivan Kovnatsky";
        language = "en-us";
        category = "Technology";
      };
      storage = {
        data_dir = dataDir;
        audio_dir = audioDir;
        metadata_dir = metadataDir;
        thumbnails_dir = thumbnailsDir;
      };
      watch = {
        enabled = true;
        file = urlsFile;
      };
      log_level = "INFO";
    }
  );

  # Substitute external domain at runtime
  runtimeConfigFile = pkgs.writeShellScript "podservice-config-gen" ''
    EXTERNAL_DOMAIN=$(cat ${config.sops.secrets.external-domain.path})
    ${pkgs.gnused}/bin/sed "s/@EXTERNAL_DOMAIN@/$EXTERNAL_DOMAIN/g" ${configFile}
  '';
in
{
  local.launchd.services.podservice = {
    enable = true;
    waitForPath = config.flags.externalStoragePath;
    inherit dataDir;
    extraDirs = [
      audioDir
      metadataDir
      thumbnailsDir
    ];
    preStart = ''
      # Generate runtime config with secrets
      ${runtimeConfigFile} > ${dataDir}/config.yaml
    '';
    command = ''
      ${pkgs.podservice}/bin/podservice serve --config=${dataDir}/config.yaml
    '';
    environment = {
      PATH = "${pkgs.coreutils}/bin:${pkgs.ffmpeg}/bin:${pkgs.nixpkgs-darwin-master-ytdlp.yt-dlp}/bin";
    };
  };
}
