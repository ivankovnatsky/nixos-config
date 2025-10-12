{
  config,
  pkgs,
  lib,
  ...
}:

let
  models = [
    "llama3.1:8b"
    "mistral:7b"
  ];

  ollamaModelsPath = "/Volumes/Storage/Data/Ollama";
in
{
  # Set system-wide environment variables for ollama commands
  environment.variables = {
    OLLAMA_MODELS = ollamaModelsPath;
    OLLAMA_HOST = "${config.flags.miniIp}:11434";
    OLLAMA_CONTEXT_LENGTH = "8192";
  };

  # Ollama server running as user agent (port 11434 is non-privileged)
  launchd.user.agents.ollama = {
    serviceConfig = {
      Label = "com.ivankovnatsky.ollama";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/agents/log/launchd/ollama.log";
      StandardErrorPath = "/tmp/agents/log/launchd/ollama.error.log";
      ThrottleInterval = 10;

      ProgramArguments = [
        "/opt/homebrew/bin/ollama"
        "serve"
      ];

      EnvironmentVariables = {
        HOME = config.users.users.ivan.home;
        PATH = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin";
        OLLAMA_MODELS = ollamaModelsPath;
        OLLAMA_HOST = "${config.flags.miniIp}:11434";
      };
    };
  };

  # System activation script to set up directories and pull models
  system.activationScripts.ollama.text = ''
    echo "Setting up Ollama directories..."
    mkdir -p /tmp/agents/log/launchd
    mkdir -p ${ollamaModelsPath}

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
