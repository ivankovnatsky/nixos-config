{ pkgs, ... }:
{
  services.ollama = {
    enable = true;
    package = pkgs.nixpkgs-nixos-master-ollama.ollama-cuda;
    host = "0.0.0.0";
    openFirewall = true;
    environmentVariables = {
      OLLAMA_CONTEXT_LENGTH = "81920";
    };
    loadModels = [
      "gemma4:31b"
      "gemma4:26b"
      "gpt-oss:20b"
    ];
  };
}
