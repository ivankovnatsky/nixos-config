{
  config,
  pkgs,
  username,
  ...
}:

let
  dataDir = "${config.flags.miniStoragePath}/Media/Textcast";
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
      text:
        provider: anthropic
        model: claude-sonnet-4-5-20250929
        strategy: condense
        condense_ratio: 0.5

      audio:
        vendor: openai
        model: tts-1-hd
        voice: nova
        format: mp3
        output_dir: ${audioDir}

    destinations:
      - type: podservice
        enabled: true
        url: https://podservice.@EXTERNAL_DOMAIN@

    server:
      enabled: true
      host: ${config.flags.miniIp}
      port: 8084
  '';

  # Substitute secrets at runtime
  runtimeConfigFile = pkgs.writeShellScript "textcast-config-gen" ''
    EXTERNAL_DOMAIN=$(cat ${config.sops.secrets.external-domain.path})
    ${pkgs.gnused}/bin/sed \
      -e "s|@EXTERNAL_DOMAIN@|$EXTERNAL_DOMAIN|g" \
      ${configFile}
  '';

  # Wrapper script to set environment variables from secrets
  textcastWrapper = pkgs.writeShellScript "textcast-wrapper" ''
    export ANTHROPIC_API_KEY=$(cat ${config.sops.secrets.anthropic-api-key.path})
    export OPENAI_API_KEY=$(cat ${config.sops.secrets.openai-api-key.path})
    exec ${pkgs.textcast}/bin/textcast service daemon --config=${configDir}/config.yaml
  '';
in
{
  # Declare sops secrets for system-level access
  # textcast runs as user agent (ivan), so set owner to ivan
  sops.secrets.anthropic-api-key = {
    key = "anthropicApiKey";
    owner = username;
  };

  sops.secrets.openai-api-key = {
    key = "openaiApiKey";
    owner = username;
  };

  local.launchd.services.textcast = {
    enable = true;
    waitForPath = config.flags.miniStoragePath;
    dataDir = dataDir;
    extraDirs = [
      audioDir
      textsDir
      logsDir
      configDir
    ];
    preStart = ''
      # Generate runtime config with secrets
      ${runtimeConfigFile} > ${configDir}/config.yaml
    '';
    command = "${textcastWrapper}";
  };
}
