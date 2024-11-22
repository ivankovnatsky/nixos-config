{ config, pkgs, ... }:

let
  jsonFormat = pkgs.formats.json { };

  editorSettings = {
    "terminal.integrated.fontFamily" = "${config.flags.fontGeneral}";
    "files.autoSave" = "onFocusChange";
    "[nix]"."editor.tabSize" = 2;
    "vim.relativeLineNumbers" = true;
    "editor.lineNumbers" = "relative";
    "scm.diffDecorations" = "all";
    "editor.renderLineHighlight" = "all";
    "diffEditor.renderSideBySide" = false;
    "diffEditor.ignoreTrimWhitespace" = false;
    "files.insertFinalNewline" = true;
    "files.trimFinalNewlines" = true;
    "editor.renderFinalNewline" = false;
  };
in
{
  programs.vscode = {
    enable = true;
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
