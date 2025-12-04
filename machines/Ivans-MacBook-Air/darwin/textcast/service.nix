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

  configFileTemplate = pkgs.writeText "textcast-config.yaml" ''
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
      text_model: gpt-5.1
      speech_model: tts-1-hd
      voice: nova
      audio_format: mp3
      output_dir: ${audioDir}
      vendor: openai

    destinations:
      - type: podservice
        enabled: true
        url: https://podservice.@EXTERNAL_DOMAIN@

    server:
      enabled: true
      host: 192.168.50.8
      port: 8084
  '';

  # Substitute secrets at runtime
  runtimeConfigFile = pkgs.writeShellScript "textcast-config-gen" ''
    EXTERNAL_DOMAIN=$(cat ${config.sops.secrets.external-domain.path})
    ${pkgs.gnused}/bin/sed \
      -e "s|@EXTERNAL_DOMAIN@|$EXTERNAL_DOMAIN|g" \
      ${configFileTemplate}
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

  sops.secrets.external-domain = {
    key = "externalDomain";
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
      # Generate runtime config with secrets
      ${runtimeConfigFile} > "${configDir}/config.yaml"
    '';
    command = "${textcastWrapper}";
  };
}
