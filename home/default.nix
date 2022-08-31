{ config, pkgs, super, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin isLinux;

  editorName = "nvim";
  homeDir = if isDarwin then "/Users" else "/home";
  helmPluginsPath = if isDarwin then "Library/helm/plugins" else ".local/share/helm/plugins";
in
{
  imports = [
    ./alacritty.nix
    ./firefox-config.nix
    ./neovim
    ./git.nix
    ./packages.nix
    ./zsh.nix

    ../modules/default.nix
  ];

  programs.go = {
    enable = true;

    goPath = "go";
  };

  programs.gpg.enable = true;

  programs.bat = {
    enable = true;
    config = { tabs = "0"; };
  };

  programs.password-store = {
    enable = true;
    package = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
    settings = {
      PASSWORD_STORE_DIR = "${homeDir}/ivan/.password-store/";
    };
  };

  home.packages = [ pkgs.ranger ];
  home.file = {
    ".config/ranger/rc.conf" = {
      text = ''
        set show_hidden true
      '';
    };

    "${helmPluginsPath}/helm-secrets".source = (config.lib.file.mkOutOfStoreSymlink
      "${pkgs.helm-secrets}");

    ".terraform.d/plugin-cache/.keep" = {
      text = ''
        keep
      '';
    };

    ".terraformrc" = {
      text = ''
        plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"
      '';
    };

    ".config/yamllint/config" = {
      text = ''
        document-start: disable
      '';
    };
  };

  home.sessionVariables = {
    AWS_VAULT_BACKEND = "pass";
    EDITOR = editorName;
    VISUAL = editorName;
  };

  programs.taskwarrior = {
    enable = true;
    dataLocation = "${homeDir}/ivan/.task/";
  };

  device = super.device;
  variables = super.variables;
}
