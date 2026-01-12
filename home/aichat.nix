{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin;

  aichatConfigPath = if isDarwin then "Library/Application Support/aichat" else ".config/aichat";

  aichatConfigFile =
    if isDarwin then
      "${config.home.homeDirectory}/Library/Application Support/aichat/config.yaml"
    else
      "${config.home.homeDirectory}/.config/aichat/config.yaml";
in
{
  # https://github.com/sigoden/aichat/blob/main/config.example.yaml
  sops.templates."aichat-config.yaml".content = ''
    ${
      if config.flags.darkMode then
        ""
      else
        ''
          light_theme: true
        ''
    }
    editor: ${config.flags.editor}
    save: true
    save_session: true
    highlight: true
    keybindings: vi
    clients:
      - type: claude
        api_base: https://api.anthropic.com/v1
        api_key: ${config.sops.placeholder.anthropic-api-key}
      - type: openai
        api_base: https://api.openai.com/v1
        api_key: ${config.sops.placeholder.openai-api-key}
      - type: openai-compatible
        name: ollama
        api_base: https://ollama.${config.sops.placeholder.external-domain}/v1
        models:
          - name: gemma3:12b
          - name: llama3.1:8b
          - name: mistral:7b
  '';

  home.packages = with pkgs; [ nixpkgs-darwin-master.aichat ];

  home.activation.linkAichatConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${config.home.homeDirectory}/${aichatConfigPath}"
    $DRY_RUN_CMD ln -sf ${config.sops.templates."aichat-config.yaml".path} "${aichatConfigFile}"
  '';
}
