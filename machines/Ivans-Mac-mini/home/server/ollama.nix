{
  config,
  lib,
  ...
}:

let
  models = [
    "llama3.1:8b"
    "mistral:7b"
  ];

  ollamaModelsPath = "${config.flags.externalStoragePath}/.ollama";
in
{
  # Ollama server running as user agent (port 11434 is non-privileged)
  local.launchd.services.ollama = {
    enable = true;
    waitForPath = config.flags.externalStoragePath;
    dataDir = ollamaModelsPath;
    environment = {
      HOME = config.home.homeDirectory;
      PATH = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin";
      OLLAMA_MODELS = ollamaModelsPath;
      OLLAMA_HOST = "${config.flags.machineBindAddress}:11434";
    };
    command = ''
      /opt/homebrew/bin/ollama serve
    '';
  };

  # Pull models on home-manager activation
  home.activation.ollamaModels = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export OLLAMA_MODELS="${ollamaModelsPath}"
    export OLLAMA_HOST="${config.flags.machineLocalAddress}:11434"

    if timeout 5 /opt/homebrew/bin/ollama list &>/dev/null; then
      ${lib.concatMapStrings (model: ''
        if ! timeout 5 /opt/homebrew/bin/ollama list | grep -q "${model}"; then
          echo "Pulling ${model} model..."
          /opt/homebrew/bin/ollama pull ${model}
        else
          echo "${model} model already present"
        fi
      '') models}
    else
      echo "Ollama not available or not running, skipping model downloads"
    fi
  '';
}
