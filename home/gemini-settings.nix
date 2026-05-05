{
  config,
  pkgs,
  ...
}:

let
  homePath = config.home.homeDirectory;

  # https://geminicli.com/docs/get-started/configuration
  # https://github.com/google-gemini/gemini-cli/blob/main/docs/get-started/configuration.md
  geminiSettings = {
    general = {
      vimMode = true;
      preferredEditor = config.flags.editor;
      disableAutoUpdate = false;
      checkpointing.enabled = true;
      previewFeatures = true;
    };
    ui = {
      theme = "Default";
      hideBanner = false;
      hideTips = false;
      showLineNumbers = true;
      showCitations = true;
    };
    privacy.usageStatisticsEnabled = false;
    model = {
      maxSessionTurns = -1;
      chatCompression.contextPercentageThreshold = 0.7;
      enableShellOutputEfficiency = true;
    };
    context = {
      fileFiltering = {
        respectGitIgnore = true;
        respectGeminiIgnore = true;
        enableRecursiveFileSearch = true;
        disableFuzzySearch = false;
      };
      discoveryMaxDirs = 200;
    };
    tools = {
      shell = {
        enableInteractiveShell = true;
        showColor = false;
      };
      autoAccept = true;
      useRipgrep = true;
      enableToolOutputTruncation = true;
      truncateToolOutputThreshold = 20000;
      truncateToolOutputLines = 1000;
    };
    security = {
      auth.selectedType = "oauth-personal";
      folderTrust.enabled = false;
    };
    advanced = {
      autoConfigureMemory = false;
      excludedEnvVars = [
        "DEBUG"
        "DEBUG_MODE"
      ];
    };
  };

  geminiSettingsJson = pkgs.writeText "gemini-settings.json" (builtins.toJSON geminiSettings);
in
{
  local.tools.settings.files = [
    {
      source = "${geminiSettingsJson}";
      target = "${homePath}/.gemini/settings.json";
      mode = "0644";
    }
  ];
}
