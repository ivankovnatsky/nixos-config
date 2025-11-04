{
  config,
  pkgs,
  ...
}:

let
  dataDir = "${config.flags.miniStoragePath}/Media/Textcast";
  audioDir = "${dataDir}/Audio";
  textsDir = "${dataDir}/Texts";
  logsDir = "${dataDir}/Logs";
  textsFile = "${textsDir}/Texts.txt";

  configFile = pkgs.writeText "textcast-config.yaml" ''
    check_interval: 5m
    log_level: INFO
    log_file: ${logsDir}/textcast-service.log

    sources:
      - type: file
        name: textcast_manual
        enabled: true
        file: ${textsFile}
        check_duplicates: true

      - type: upload
        name: textcast_audio_upload
        enabled: true
        watch_dir: ${audioDir}
        file_patterns: ["*.mp3", "*.m4a", "*.wav", "*.flac"]
        check_duplicates: false

    processing:
      strategy: condense
      condense_ratio: 0.5
      text_model: gpt-4-turbo-preview
      speech_model: tts-1-hd
      voice: nova
      audio_format: mp3
      output_dir: ${audioDir}
      vendor: openai

    audiobookshelf:
      server: "@ABS_URL@"
      api_key: "@ABS_API_KEY@"
      library_name: ""
  '';

  # Substitute secrets at runtime
  runtimeConfigFile = pkgs.writeShellScript "textcast-config-gen" ''
    ABS_URL=$(cat ${config.sops.secrets.audiobookshelf-url.path})
    ABS_API_KEY=$(cat ${config.sops.secrets.audiobookshelf-api-token.path})
    ${pkgs.gnused}/bin/sed \
      -e "s|@ABS_URL@|$ABS_URL|g" \
      -e "s|@ABS_API_KEY@|$ABS_API_KEY|g" \
      ${configFile}
  '';

  # Wrapper script to set environment variables from secrets
  textcastWrapper = pkgs.writeShellScript "textcast-wrapper" ''
    export OPENAI_API_KEY=$(cat ${config.sops.secrets.openai-api-key.path})
    export ABS_URL=$(cat ${config.sops.secrets.audiobookshelf-url.path})
    export ABS_API_KEY=$(cat ${config.sops.secrets.audiobookshelf-api-token.path})
    exec ${pkgs.textcast}/bin/textcast service daemon --config=${dataDir}/config.yaml
  '';
in
{
  # Declare sops secrets for system-level access
  # textcast runs as user agent (ivan), so set owner to ivan
  sops.secrets.openai-api-key = {
    key = "openaiApiKey";
    owner = "ivan";
  };

  sops.secrets.audiobookshelf-url = {
    key = "audiobookshelf/url";
    owner = "ivan";
  };

  sops.secrets.audiobookshelf-api-token = {
    key = "audiobookshelf/apiToken";
    owner = "ivan";
  };

  local.launchd.services.textcast = {
    enable = true;
    waitForPath = config.flags.miniStoragePath;
    dataDir = dataDir;
    extraDirs = [
      audioDir
      textsDir
      logsDir
    ];
    preStart = ''
      # Generate runtime config with secrets
      ${runtimeConfigFile} > ${dataDir}/config.yaml
    '';
    command = "${textcastWrapper}";
  };
}
