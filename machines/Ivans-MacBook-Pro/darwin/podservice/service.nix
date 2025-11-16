{
  config,
  pkgs,
  username,
  ...
}:

let
  homePath = "${config.users.users.${username}.home}";
  dataDir = "${homePath}/Library/Application Support/Podservice";
  audioDir = "${dataDir}/audio";
  metadataDir = "${dataDir}/metadata";
  urlsFile = "${dataDir}/urls.txt";

  configFile = pkgs.writeText "podservice-config.yaml" (builtins.toJSON {
    server = {
      port = 8083;
      host = "192.168.50.7";
      base_url = "http://192.168.50.7:8083";
    };
    podcast = {
      title = "My YouTube Podcast";
      description = "YouTube videos converted to podcast episodes";
      author = "Ivan Kovnatsky";
      language = "en-us";
      category = "Technology";
      image_url = null;
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
in
{
  local.launchd.services.podservice = {
    enable = true;
    dataDir = dataDir;
    extraDirs = [
      audioDir
      metadataDir
    ];
    command = ''
      ${pkgs.podservice}/bin/podservice serve --config=${configFile}
    '';
    environment = {
      PATH = "${pkgs.coreutils}/bin:${pkgs.ffmpeg}/bin:${pkgs.nixpkgs-master.yt-dlp}/bin";
    };
  };
}
