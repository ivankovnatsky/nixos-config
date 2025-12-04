{
  config,
  pkgs,
  username,
  ...
}:

let
  dataDir = "${config.users.users.${username}.home}/Library/Application Support/Textcast";
  audioDir = "${dataDir}/Audio";
  textsDir = "${dataDir}/Texts";
  logsDir = "${dataDir}/Logs";
  configDir = "${dataDir}/Config";
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

    processing:
      strategy: condense
      condense_ratio: 0.5
      text_model: gpt-4-turbo-preview
      speech_model: tts-1-hd
      voice: nova
      audio_format: mp3
      output_dir: ${audioDir}
      vendor: openai

    server:
      enabled: true
      host: 192.168.50.8
      port: 8084
  '';

  # Wrapper script to set environment variables from secrets
  textcastWrapper = pkgs.writeShellScript "textcast-wrapper" ''
    export OPENAI_API_KEY=$(cat ${config.sops.secrets.openai-api-key.path})
    exec ${pkgs.textcast}/bin/textcast service daemon --config="${configDir}/config.yaml"
  '';
in
{
  sops.secrets.openai-api-key = {
    key = "openaiApiKey";
    owner = "ivan";
  };

  local.launchd.services.textcast = {
    enable = true;
    dataDir = dataDir;
    extraDirs = [
      audioDir
      textsDir
      logsDir
      configDir
    ];
    preStart = ''
      cp ${configFile} "${configDir}/config.yaml"
    '';
    command = "${textcastWrapper}";
  };
}
