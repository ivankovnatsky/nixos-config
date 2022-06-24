{ config, pkgs, super, ... }:

let
  editorName = "nvim";
  inherit (pkgs.stdenv.targetPlatform) isDarwin isLinux;

  homeDir = if isDarwin then "/Users" else "/home";

in
{
  imports = [
    ./firefox-config.nix
    ./neovim
    ./git.nix
    ./tmux.nix
    ./packages.nix
    ./zsh.nix

    ../modules/default.nix
    ../modules/secrets.nix
  ];

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
  };

  home.sessionVariables = {
    AWS_VAULT_BACKEND = "pass";
    EDITOR = editorName;
    LPASS_AGENT_TIMEOUT = "0";
    VISUAL = editorName;
  };

  programs.taskwarrior = {
    enable = true;
    dataLocation = "${homeDir}/ivan/.task/";
  };

  programs.rbw = {
    enable = true;
    package = (pkgs.rbw.override { withFzf = true; });

    settings = {
      email = "${config.secrets.email}";
      lock_timeout = 2419200;
      pinentry = pkgs.pinentry;
    };
  };

  home.file = {
    ".local/share/helm/plugins/helm-secrets".source = (config.lib.file.mkOutOfStoreSymlink
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

  device = super.device;
  variables = super.variables;
  secrets = super.secrets;
}
