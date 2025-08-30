{ config, pkgs, ... }:

{
  services.open-webui = {
    enable = true;
    host = config.flags.beeIp;
    port = 8090;

    openFirewall = true;
    
    environment = {
      # Use the load-balanced Ollama endpoint via Caddy reverse proxy
      OLLAMA_API_BASE_URL = "https://ollama.${config.secrets.externalDomain}";
      
      ENABLE_WEB_SEARCH = "true";
      WEB_SEARCH_ENGINE = "duckduckgo";

      DEFAULT_MODELS = "llama3.1:8b, mistral:7b";
    };
  };
}