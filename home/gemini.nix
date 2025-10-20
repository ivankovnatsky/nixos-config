{ config, ... }:

{
  home = {
    file = {
      # https://geminicli.com/docs/get-started/configuration
      # Available settings: https://github.com/google-gemini/gemini-cli/blob/main/docs/get-started/configuration.md
      ".gemini/settings.json" = {
        text = ''
          {
            "general": {
              "vimMode": true,
              "preferredEditor": "${config.flags.editor}",
              "disableAutoUpdate": false,
              "checkpointing": {
                "enabled": true
              }
            },
            "ui": {
              "hideBanner": false,
              "hideTips": false,
              "showLineNumbers": true,
              "showCitations": true
            },
            "privacy": {
              "usageStatisticsEnabled": false
            },
            "model": {
              "maxSessionTurns": -1,
              "chatCompression": {
                "contextPercentageThreshold": 0.7
              },
              "enableShellOutputEfficiency": true
            },
            "context": {
              "fileFiltering": {
                "respectGitIgnore": true,
                "respectGeminiIgnore": true,
                "enableRecursiveFileSearch": true,
                "disableFuzzySearch": false
              },
              "discoveryMaxDirs": 200
            },
            "tools": {
              "shell": {
                "enableInteractiveShell": true,
                "showColor": false
              },
              "autoAccept": false,
              "useRipgrep": true,
              "enableToolOutputTruncation": true,
              "truncateToolOutputThreshold": 20000,
              "truncateToolOutputLines": 1000
            },
            "security": {
              "auth": {
                "selectedType": "oauth-personal"
              },
              "folderTrust": {
                "enabled": false
              }
            },
            "advanced": {
              "autoConfigureMemory": false,
              "excludedEnvVars": ["DEBUG", "DEBUG_MODE"]
            }
          }
        '';
      };
    };
  };
}
