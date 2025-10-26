{ config, pkgs, ... }:

{
  # Sops template for open-webui environment with dynamic domain
  sops.templates."open-webui.env" = {
    content = ''
      OLLAMA_API_BASE_URL=https://ollama.${config.sops.placeholder.external-domain}
    '';
    mode = "0444";
  };

  services.open-webui = {
    enable = true;
    host = config.flags.beeIp;
    port = 8090;

    openFirewall = true;

    # Environment variables reference: https://docs.openwebui.com/getting-started/env-configuration/
    environment = {
      ENABLE_WEB_SEARCH = "true";
      WEB_SEARCH_ENGINE = "duckduckgo";

      DEFAULT_MODELS = "llama3.1:8b, mistral:7b";

      # Disable changelog/update notifications
      ENABLE_VERSION_UPDATE_CHECK = "false";
    };
  };

  # Load OLLAMA_API_BASE_URL from sops template
  systemd.services.open-webui.serviceConfig.EnvironmentFile = [
    config.sops.templates."open-webui.env".path
  ];
}
