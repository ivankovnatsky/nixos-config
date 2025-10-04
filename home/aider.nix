{ config, pkgs, ... }:

{
  home = {
    packages = [ pkgs.nixpkgs-master.aider-chat ];

    # Create aider config files
    file = {
      ".aider.conf.yml" = {
        text = ''
          # Use Ollama model
          model: ollama_chat/llama3.1:8b

          # Editor settings
          edit-format: diff

          # Git settings
          auto-commits: false
          dirty-commits: false
          gitignore: false

          # Display settings
          dark-mode: true
          pretty: true
          # stream: true

          # Map settings (use larger context for better code understanding)
          map-tokens: 8192

          # Cache settings
          # cache-prompts: true

          # Timeout settings (in seconds) - increase for slow model loading
          timeout: 60

          # Model warnings
          show-model-warnings: false

          # Voice settings (optional)
          # voice-language: en
        '';
      };
    };

    # Set environment variables for Ollama API
    sessionVariables = {
      # Point to Ollama instance via Caddy reverse proxy
      OLLAMA_API_BASE = "https://ollama.${config.secrets.externalDomain}";

      # Extended context for better code understanding
      OLLAMA_CONTEXT_LENGTH = "8192";
    };
  };
}
