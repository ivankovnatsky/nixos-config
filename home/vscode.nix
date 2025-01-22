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
    "editor.renderFinalNewline" = "off";
    "editor.renderLineHighlight" = "all";
    "extensions.autoCheckUpdates" = false;
    "files.autoSave" = "onFocusChange";
    "files.insertFinalNewline" = true;
    "files.trimFinalNewlines" = true;
    "git.openRepositoryInParentFolders" = "always";
    "git.autofetch" = "all";
    "scm.diffDecorations" = "all";
    "terminal.integrated.fontFamily" = "Hack Nerd Font";
    "update.mode" = "none";
    "vim.relativeLineNumbers" = true;
    "security.workspace.trust.enabled" = false;

    # Auto-switching themes
    "window.autoDetectColorScheme" = true;
    "workbench.preferredDarkColorTheme" = "Default Dark+";
    "workbench.preferredLightColorTheme" = "Default Light+";
    "workbench.colorTheme" = "Auto";
  };
in
{
  programs.vscode = {
    inherit (config.flags.apps.vscode) enable;
    package = pkgs.vscode;
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;
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
    ];
  };

  # Add Cursor settings with proper formatting
  home.file."Library/Application Support/Cursor/User/settings.json".source =
    jsonFormat.generate "cursor-user-settings" editorSettings;

  # Windsurf
  home.file."Library/Application Support/Windsurf/User/settings.json".source =
    jsonFormat.generate "windsurf-user-settings" editorSettings;
}
