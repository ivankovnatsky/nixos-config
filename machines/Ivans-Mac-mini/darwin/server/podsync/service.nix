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

  # Template config without secrets (substituted at runtime)
  configTomlTemplate = pkgs.runCommand "podsync-config.toml.template"
    {
      ytDlpPath = "${pkgs.yt-dlp}/bin/yt-dlp";
      miniIp = config.flags.miniIp;
    }
    ''
      ${pkgs.gnused}/bin/sed \
        -e "s|@ytDlpPath@|$ytDlpPath|g" \
        -e "s|@miniIp@|$miniIp|g" \
        ${configTomlPath} > $out
    '';
in
{
  # Sops secrets for podsync API keys
  sops.secrets.podsync-youtube-api-key = {
    key = "podsync/youtubeApiKey";
    owner = "ivan";
  };

  sops.secrets.podsync-vimeo-api-key = {
    key = "podsync/vimeoApiKey";
    owner = "ivan";
  };

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

      # Read secrets from sops at runtime
      YOUTUBE_API_KEY=$(cat ${config.sops.secrets.podsync-youtube-api-key.path})
      VIMEO_API_KEY=$(cat ${config.sops.secrets.podsync-vimeo-api-key.path})

      # Remove old config if it exists (may be read-only)
      rm -f ${configDir}/config.toml

      # Substitute secrets and config values at runtime (keeps secrets out of /nix/store)
      ${pkgs.gnused}/bin/sed \
        -e "s|@externalDomain@|${config.secrets.externalDomain}|g" \
        -e "s|@youtubeApiKey@|$YOUTUBE_API_KEY|g" \
        -e "s|@vimeoApiKey@|$VIMEO_API_KEY|g" \
        ${configTomlTemplate} > ${configDir}/config.toml
    '';
    command = ''
      ${pkgs.podsync}/bin/podsync --config=${configDir}/config.toml
    '';
  };
}
