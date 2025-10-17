{
  config,
  pkgs,
  ...
}:

let
  volumePath = "/Volumes/Storage";
  podsyncDir = "${volumePath}/Data/.podsync";
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
  launchd.user.agents.podsync = {
    serviceConfig = {
      Label = "com.ivankovnatsky.podsync";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/agents/log/launchd/podsync.log";
      StandardErrorPath = "/tmp/agents/log/launchd/podsync.error.log";
      ThrottleInterval = 10;
    };

    command =
      let
        podsyncScript = pkgs.writeShellScriptBin "podsync-starter" ''
          /bin/wait4path "${volumePath}"

          mkdir -p ${configDir}
          mkdir -p ${dataDir}
          mkdir -p ${dbDir}
          mkdir -p ${logDir}

          # Copy processed config to config directory (force to overwrite read-only files)
          cp -f ${configToml} ${configDir}/config.toml

          # Add ffmpeg and deno to PATH (yt-dlp path is in config)
          export PATH="${pkgs.ffmpeg}/bin:${pkgs.deno}/bin:$PATH"

          # Run podsync with config file
          exec ${pkgs.podsync}/bin/podsync --config=${configDir}/config.toml
        '';
      in
      "${podsyncScript}/bin/podsync-starter";
  };
}
