{
  config,
  pkgs,
  ...
}:

let
  podsyncDir = "${config.flags.miniStoragePath}/.podsync";
  configDir = "${podsyncDir}/config";
  dataDir = "${podsyncDir}/data";
  dbDir = "${podsyncDir}/db";
  logDir = "${podsyncDir}/log";

  # Path to the config.toml template
  configTomlPath = ./config.toml;

  # Process the config.toml template with secrets
  configToml = pkgs.runCommand "podsync-config.toml"
    {
      externalDomain = config.secrets.externalDomain;
      youtubeApiKey = config.secrets.podsync.youtubeApiKey;
      vimeoApiKey = config.secrets.podsync.vimeoApiKey;
      ytDlpPath = "${pkgs.yt-dlp}/bin/yt-dlp";
      miniIp = config.flags.miniIp;
    }
    ''
      substituteAll ${configTomlPath} $out
    '';
in
{
  local.launchd.services.podsync = {
    enable = true;
    waitForPath = config.flags.miniStoragePath;
    dataDir = podsyncDir;
    extraDirs = [
      configDir
      dataDir
      dbDir
      logDir
    ];
    preStart = ''
      export PATH="${pkgs.ffmpeg}/bin:${pkgs.deno}/bin:$PATH"
      cp -f ${configToml} ${configDir}/config.toml
    '';
    command = ''
      ${pkgs.podsync}/bin/podsync --config=${configDir}/config.toml
    '';
  };
}
