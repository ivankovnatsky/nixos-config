{ config, ... }:

{
  # WEBUI_URL needs the public domain so OAuth redirects and email/link
  # generation work correctly. external-domain is a sops secret, so render it
  # via a sops template and feed the result to the service via environmentFile.
  sops.templates."open-webui.env" = {
    content = ''
      WEBUI_URL=https://openwebui.${config.sops.placeholder.external-domain}
    '';
    restartUnits = [ "open-webui.service" ];
  };

  services.open-webui = {
    enable = true;
    host = "0.0.0.0";
    port = 8091;
    openFirewall = true;
    environmentFile = config.sops.templates."open-webui.env".path;
    environment = {
      OLLAMA_BASE_URLS = "http://127.0.0.1:${toString config.services.ollama.port}";

      ENABLE_WEB_SEARCH = "true";
      DEFAULT_MODELS = "gemma3:27b";

      SCARF_NO_ANALYTICS = "true";
      DO_NOT_TRACK = "true";
      ANONYMIZED_TELEMETRY = "false";
      ENABLE_VERSION_UPDATE_CHECK = "false";
    };
  };
}
