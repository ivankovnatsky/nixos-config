{ config, lib, pkgs, super, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin;

  editorName = "nvim";
  homeDir = if isDarwin then "/Users" else "/home";
  aichatConfigPath = if isDarwin then "Library/Application Support/aichat/config.yaml" else ".config/aichat/config.yaml";
in
{
  imports = [
    ./k9s.nix
    ./neovim
    ./git.nix
    ./ssh.nix
    ./packages.nix
    ./shell.nix

    ../modules/default.nix
  ];

  programs.go = {
    enable = true;
    package = pkgs.nixpkgs-unstable.go;

    goPath = "go";
  };

  programs.gpg.enable = true;
  programs.nushell.enable = true;

  programs.bat = {
    enable = true;
    config = { tabs = "0"; };
  };

  home.packages = [ pkgs.ranger ];
  home.file = {
    ".config/ranger/rc.conf" = {
      text = ''
        set show_hidden true
      '';
    };

    ".terraform.d/plugin-cache/.keep" = {
      text = ''
        keep
      '';
    };

    ".npmrc".text = ''
      prefix=~/.npm
    '';

    ".terraformrc" = {
      # https://developer.hashicorp.com/terraform/cli/config/config-file
      text = ''
        plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"
        plugin_cache_may_break_dependency_lock_file = true
        disable_checkpoint = true
      '';
    };

    ".config/yamllint/config" = {
      text = ''
        document-start: disable
      '';
    };

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
      '';
    };
  };

  home.activation = {
    createAndSetPermissionsNetrc =
      let
        netrcContent = pkgs.writeText "tmp_netrc" ''
          default api.github.com login ivankovnatsky password ${config.secrets.gitApiTokenRepoScope}
        '';
      in
      lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        cp "${netrcContent}" "$HOME/.netrc"
        chmod 0600 "$HOME/.netrc"
      '';
  };

  home.sessionVariables = {
    AWS_VAULT_BACKEND = "pass";
    EDITOR = editorName;
    VISUAL = editorName;
    # https://github.com/kovidgoyal/kitty/issues/879
    TERM = "xterm-256color";
  };

  programs.taskwarrior = {
    enable = true;
    dataLocation = "${homeDir}/ivan/.task/";
  };

  device = super.device;
  variables = super.variables;
}
