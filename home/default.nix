{ config, lib, pkgs, super, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin;

  editorName = "nvim";
  homeDir = if isDarwin then "/Users" else "/home";
  helmPluginsPath = if isDarwin then "Library/helm/plugins" else ".local/share/helm/plugins";
  aichatConfigPath = if isDarwin then "Library/Application Support/aichat/config.yaml" else ".config/aichat/config.yaml";
in
{
  imports = [
    ./firefox-config.nix
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

  programs.password-store = {
    enable = true;
    package = pkgs.pass.withExtensions (exts: [ exts.pass-otp exts.pass-import ]);
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
        save: true
        highlight: true
        wrap: 80
        wrap_code: true
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
