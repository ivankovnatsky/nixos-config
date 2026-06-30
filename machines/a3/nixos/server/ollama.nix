{ pkgs, ... }:
{
  services.ollama = {
    enable = true;
    package = pkgs.nixpkgs-nixos-master-ollama.ollama-cuda;
    host = "0.0.0.0";
    openFirewall = true;
    environmentVariables = {
      OLLAMA_CONTEXT_LENGTH = "8192";
    };
    loadModels = [
      "gemma3:27b"
      "gemma4:31b"
      "gpt-oss:20b"
    ];
  };
}
