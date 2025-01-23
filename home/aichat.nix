{ config, pkgs, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin;

  aichatConfigPath = if isDarwin then "Library/Application Support/aichat/config.yaml" else ".config/aichat/config.yaml";
in
{
  home = {
    packages = with pkgs; [ aichat ];
    file = {
      # https://github.com/sigoden/aichat/blob/main/config.example.yaml
      "${aichatConfigPath}" = {
        text = ''
          ${if config.flags.darkMode then "" else
          ''
          light_theme: true
          ''
          }
          save: true
          highlight: true
          keybindings: vi
          clients:
            - type: claude
              api_base: https://api.anthropic.com/v1
              api_key: ${config.secrets.anthropicApiKey}
            - type: openai
              api_base: https://api.openai.com/v1
              api_key: ${config.secrets.openaiApiKey}
            - type: openai-compatible
              name: ollama
              api_base: http://localhost:11434/v1
              models:
                - name: llama3.1:8b
                - name: deepseek-r1:14b
        '';
      };
    };
  };
}
