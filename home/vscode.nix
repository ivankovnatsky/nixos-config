{ config, pkgs, ... }:

let
  jsonFormat = pkgs.formats.json { };

  editorSettings = {
    "[nix]" = {
      "editor.tabSize" = 2;
    };
    "diffEditor.ignoreTrimWhitespace" = false;
    "diffEditor.renderSideBySide" = false;
    "editor.lineNumbers" = "relative";
    "editor.minimap.enabled" = false;
    "editor.renderFinalNewline" = "off";
    "editor.renderLineHighlight" = "all";
    "extensions.autoCheckUpdates" = false;
    "extensions.ignoreRecommendations" = true;
    "files.autoSave" = "onFocusChange";
    "files.enableTrash" = false;
    "files.insertFinalNewline" = true;
    "files.trimFinalNewlines" = true;
    "git.autofetch" = "all";
    "git.openRepositoryInParentFolders" = "always";
    "scm.diffDecorations" = "all";
    "security.workspace.trust.enabled" = false;
    "terminal.integrated.fontFamily" = "Hack Nerd Font";
    "update.mode" = "manual";
    "vim.relativeLineNumbers" = true;
    "window.autoDetectColorScheme" = true;
    "windsurf.autoExecutionPolicy" = "off";
    "windsurf.autocompleteSpeed" = "default";
    "windsurf.chatFontSize" = "default";
    "windsurf.openRecentConversation" = true;
    "windsurf.rememberLastModelSelection" = true;
    "workbench.colorTheme" = "Auto";
    "workbench.preferredDarkColorTheme" = "Default Dark+";
    "workbench.preferredLightColorTheme" = "Default Light+";
  };
in
{
  programs.vscode = {
    inherit (config.flags.apps.vscode) enable;
    package = pkgs.vscode;
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;
    mutableExtensionsDir = false;
    userSettings = editorSettings;

    extensions = with pkgs.vscode-extensions; [
      vscodevim.vim
      jnoortheen.nix-ide
      hashicorp.terraform
      eamodio.gitlens
      # GitHub.copilot # Can't be installed on VSCodium
      ms-vscode.makefile-tools
      ms-python.python
      hashicorp.hcl
      golang.go
      ms-azuretools.vscode-docker
      # Nushell
      thenuprojectcontributors.vscode-nushell-lang
      # saoudrizwan.claude-dev
    ];
  };

  # Add Cursor settings with proper formatting
  home.file."Library/Application Support/Cursor/User/settings.json".source =
    jsonFormat.generate "cursor-user-settings" editorSettings;

  # Windsurf
  home.file."Library/Application Support/Windsurf/User/settings.json".source =
    jsonFormat.generate "windsurf-user-settings" editorSettings;
}
