{ config, ... }:

{
  services.open-webui = {
    enable = true;
    host = "0.0.0.0";
    port = 8091;
    openFirewall = true;
    environment = {
      OLLAMA_BASE_URLS = "http://127.0.0.1:${toString config.services.ollama.port}";
      WEBUI_URL = "http://${config.flags.a3Ip}:8091";

      ENABLE_WEB_SEARCH = "true";
      DEFAULT_MODELS = "gemma3:27b";

      SCARF_NO_ANALYTICS = "True";
      DO_NOT_TRACK = "True";
      ANONYMIZED_TELEMETRY = "False";
      ENABLE_VERSION_UPDATE_CHECK = "False";
    };
  };
}
