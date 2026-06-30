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
    syncModels = true;
    loadModels = [
      "gpt-oss:20b"
    ];
  };
}
