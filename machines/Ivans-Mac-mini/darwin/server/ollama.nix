{ config, ... }:

let
  ollamaModelsPath = "${config.flags.externalStoragePath}/.ollama";
in
{
  # Set system-wide environment variables for ollama commands
  environment.variables = {
    OLLAMA_MODELS = ollamaModelsPath;
    OLLAMA_HOST = "${config.flags.machineLocalAddress}:11434";
    OLLAMA_CONTEXT_LENGTH = "8192";
  };
}
