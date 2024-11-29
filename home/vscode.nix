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
    "scm.diffDecorations" = "all";
    "terminal.integrated.fontFamily" = "Hack Nerd Font";
    "update.mode" = "none";
    "vim.relativeLineNumbers" = true;
  };
in
{
  programs.vscode = {
    inherit (config.flags.apps.vscode) enable;
    package = pkgs.vscodium;
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;
    userSettings = editorSettings;

    extensions = with pkgs.vscode-extensions; [
      vscodevim.vim
      jnoortheen.nix-ide
      hashicorp.terraform
      eamodio.gitlens
    ];
  };

  # Add Cursor settings with proper formatting
  home.file."Library/Application Support/Cursor/User/settings.json".source =
    jsonFormat.generate "cursor-user-settings" editorSettings;
}
