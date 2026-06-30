{
  config,
  pkgs,
  ...
}:

let
  homePath = config.home.homeDirectory;

  # pi-coding-agent custom providers / models.
  # Docs: https://github.com/earendil-works/pi-coding-agent/blob/main/docs/models.md
  # File is reloaded each time `/model` is opened in pi — no restart needed.
  piModels = {
    providers = {
      # Local Ollama instance. `apiKey` is required by the schema but
      # ignored by Ollama, so any value works.
      ollama = {
        baseUrl = "http://localhost:11434/v1";
        api = "openai-completions";
        apiKey = "ollama";
        # Most OpenAI-compatible local servers don't understand the
        # `developer` role or `reasoning_effort` parameter.
        compat = {
          supportsDeveloperRole = false;
          supportsReasoningEffort = false;
        };
        # Keep this list in sync with
        # machines/a3/nixos/server/ollama.nix `services.ollama.loadModels`.
        # `contextWindow` matches the server-side `OLLAMA_CONTEXT_LENGTH`.
        models = [
          {
            id = "gemma3:27b";
            contextWindow = 8192;
          }
          {
            id = "gemma4:31b";
            contextWindow = 8192;
          }
          {
            id = "gpt-oss:20b";
            reasoning = true;
            contextWindow = 8192;
          }
        ];
      };
    };
  };

  # `pkgs.formats.json` pretty-prints (2-space indent) so the deployed
  # file stays human-readable, unlike `builtins.toJSON` which collapses
  # everything onto one line.
  piModelsJson = (pkgs.formats.json { }).generate "pi-models.json" piModels;
in
{
  local.tools.settings.files = [
    {
      source = "${piModelsJson}";
      target = "${homePath}/.pi/agent/models.json";
      mode = "0644";
    }
  ];
}
