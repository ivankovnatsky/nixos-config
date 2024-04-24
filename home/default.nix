{ config, lib, pkgs, super, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin;

  homeDir = if isDarwin then "/Users" else "/home";
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
    EDITOR = config.variables.editor;
    VISUAL = config.variables.editor;
    # https://github.com/kovidgoyal/kitty/issues/879
    TERM = "xterm-256color";
    # This is needed for aiac
    OPENAI_API_KEY = "${config.secrets.openaiApikey}";
  };

  # https://github.com/nix-community/home-manager/blob/master/modules/programs/taskwarrior.nix
  programs.taskwarrior = {
    enable = true;
    dataLocation = "${homeDir}/ivan/.task/";
    colorTheme = if config.variables.darkMode then "no-color" else "light-256";
  };

  device = super.device;
  variables = super.variables;
}
