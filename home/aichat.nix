{ config, pkgs, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin;

  aichatConfigPath = if isDarwin then "Library/Application Support/aichat/config.yaml" else ".config/aichat/config.yaml";
in
{
  home = {
    packages = with pkgs; [ nixpkgs-master.aichat ];
    file = {
      "${aichatConfigPath}" = {
        text = ''
          model: openai:gpt-4-turbo-preview
          ${if config.variables.darkMode then "" else
          ''
          light_theme: true
          ''
          }
          save: true
          highlight: true
          keybindings: vi
          clients:
          - type: openai
            api_key: ${config.secrets.openaiApikey}
          - type: ollama
            api_base: http://localhost:11434
            models:
              - name: llama3:8b
                max_input_tokens: 8192
        '';
      };
    };
  };
}
