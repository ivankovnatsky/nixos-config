{ config, pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;
    userSettings = {
      "terminal.integrated.fontFamily" = "${config.flags.fontGeneral}";
      "files.autoSave" = "off";
      "[nix]"."editor.tabSize" = 2;
      "vim.relativeLineNumbers" = true;
      "editor.lineNumbers" = "relative";
    };

    extensions = with pkgs.vscode-extensions; [
      vscodevim.vim

      jnoortheen.nix-ide

      hashicorp.terraform
    ];
  };
}
