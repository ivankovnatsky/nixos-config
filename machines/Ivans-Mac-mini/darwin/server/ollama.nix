{
  config,
  pkgs,
  lib,
  username,
  ...
}:

let
  models = [
    "llama3.1:8b"
    "mistral:7b"
  ];

  ollamaModelsPath = "${config.flags.miniStoragePath}/.ollama";
in
{
  # Set system-wide environment variables for ollama commands
  environment.variables = {
    OLLAMA_MODELS = ollamaModelsPath;
    OLLAMA_HOST = "${config.flags.miniIp}:11434";
    OLLAMA_CONTEXT_LENGTH = "8192";
  };

  # Ollama server running as user agent (port 11434 is non-privileged)
  local.launchd.services.ollama = {
    enable = true;
    type = "user-agent";
    waitForPath = config.flags.miniStoragePath;
    dataDir = ollamaModelsPath;
    environment = {
      HOME = config.users.users.${username}.home;
      PATH = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin";
      OLLAMA_MODELS = ollamaModelsPath;
      OLLAMA_HOST = "${config.flags.miniIp}:11434";
    };
    command = ''
      /opt/homebrew/bin/ollama serve
    '';
  };

  # System activation script to pull models
  system.activationScripts.ollama.text = ''
    # Set environment variables for ollama
    export OLLAMA_MODELS="${ollamaModelsPath}"
    export OLLAMA_HOST="${config.flags.miniIp}:11434"

    # Check if brew ollama service is running and responsive with timeout
    if timeout 5 /opt/homebrew/bin/ollama list &>/dev/null; then
      ${lib.concatMapStrings (model: ''
        # Check if ${model} is already downloaded
        if ! timeout 5 /opt/homebrew/bin/ollama list | grep -q "${model}"; then
          echo "Pulling ${model} model..."
          /opt/homebrew/bin/ollama pull ${model}
        else
          echo "${model} model already present"
        fi
      '') models}
    else
      echo "Brew ollama not available or not running, skipping model downloads"
      echo "Please install with: brew install ollama"
      echo "You can manually pull the models later with:"
      ${lib.concatMapStrings (model: ''
        echo "  OLLAMA_MODELS=${ollamaModelsPath} /opt/homebrew/bin/ollama pull ${model}"
      '') models}
    fi
  '';
}
