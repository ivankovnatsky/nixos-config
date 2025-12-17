{
  config,
  pkgs,
  lib,
  ...
}:

let
  openWebuiDataPath = "${config.flags.miniStoragePath}/.open-webui";
in
{
  # Open WebUI server running as user agent (port 8090 is non-privileged)
  local.launchd.services.open-webui = {
    enable = true;
    waitForPath = config.flags.miniStoragePath;
    dataDir = openWebuiDataPath;
    environment = {
      HOME = config.users.users.ivan.home;
      PATH = "${pkgs.nixpkgs-master.open-webui}/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin";

      # State directories
      DATA_DIR = "${openWebuiDataPath}/data";
      STATIC_DIR = "${openWebuiDataPath}/static";
      HF_HOME = "${openWebuiDataPath}/hf_home";
      SENTENCE_TRANSFORMERS_HOME = "${openWebuiDataPath}/transformers_home";

      # Open WebUI configuration
      WEBUI_URL = "http://${config.flags.miniIp}:8090";

      # Secret key for session management (generated once)
      WEBUI_SECRET_KEY_FILE = "${openWebuiDataPath}/config/secret_key";

      # Ollama integration - use local Ollama instance
      OLLAMA_API_BASE_URL = "http://${config.flags.miniIp}:11434";

      # Web search settings
      ENABLE_WEB_SEARCH = "true";

      # Default models
      DEFAULT_MODELS = "llama3.1:8b,mistral:7b";

      # Disable telemetry and version checks
      SCARF_NO_ANALYTICS = "true";
      DO_NOT_TRACK = "true";
      ANONYMIZED_TELEMETRY = "false";
      ENABLE_VERSION_UPDATE_CHECK = "false";
    };
    command = ''
      # Create data directories if they don't exist
      mkdir -p "${openWebuiDataPath}/data"
      mkdir -p "${openWebuiDataPath}/static"
      mkdir -p "${openWebuiDataPath}/hf_home"
      mkdir -p "${openWebuiDataPath}/transformers_home"
      mkdir -p "${openWebuiDataPath}/config"

      # Generate secret key if it doesn't exist
      if [ ! -f "${openWebuiDataPath}/config/secret_key" ]; then
        echo "Generating new WEBUI_SECRET_KEY..."
        head -c 32 /dev/urandom | base64 > "${openWebuiDataPath}/config/secret_key"
      fi

      # Start Open WebUI
      export WEBUI_SECRET_KEY=$(cat "${openWebuiDataPath}/config/secret_key")
      ${pkgs.nixpkgs-master.open-webui}/bin/open-webui serve --host "${config.flags.miniIp}" --port 8090
    '';
  };
}
