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
    };
  };
}
