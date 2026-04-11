{ pkgs, ... }:
{
  services.ollama = {
    enable = true;
    package = pkgs.nixpkgs-nixos-master-ollama.ollama-cuda;
    host = "0.0.0.0";
    openFirewall = true;
    loadModels = [
      "gemma3:27b"
      "gemma4:31b"
      "gpt-oss:20b"
    ];
  };

  # Claude Code local development via Ollama's Anthropic-compatible API
  # environment.variables = {
  #   ANTHROPIC_BASE_URL = "http://localhost:11434";
  #   ANTHROPIC_API_KEY = "ollama";
  # };
}
