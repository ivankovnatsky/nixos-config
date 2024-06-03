{ config, lib, pkgs, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin isLinux;

  syncthingHomeDir = if isDarwin then "~/Library/Application\\ Support/Syncthing" else "~/.config/syncthing";

  shellAliases = {
    cat = "${pkgs.bat}/bin/bat";
    curl = "${pkgs.curlie}/bin/curlie";
    dig = "${pkgs.doggo}/bin/doggo";
    du = "${pkgs.du-dust}/bin/dust";
    dog = "${pkgs.doggo}/bin/doggo";
    fd = "${pkgs.fd}/bin/fd --hidden --no-ignore";
    k = "${pkgs.kubectl}/bin/kubectl";
    grep = "${pkgs.ripgrep}/bin/rg";
    ls = "${pkgs.lsd}/bin/lsd --group-dirs first --icon always";
    tree = "${pkgs.lsd}/bin/lsd --tree";
    rclone = "${pkgs.rclone}/bin/rclone -P";
    stc = "${pkgs.stc-cli}/bin/stc -homedir ${syncthingHomeDir}";
    wl-copy = lib.mkIf isLinux "${pkgs.wl-clipboard}/bin/wl-copy -n";
    tf = "${pkgs.terraform}/bin/terraform";
    transmission = "${pkgs.transmission}/bin/transmission-remote --list";

    g = "${pkgs.git}/bin/git";
  };
in
{
  home.packages = with pkgs; [
    fd
    zsh-forgit
    # Install grc only when config.flags.enableFishShell = true
    (lib.mkIf config.flags.enableFishShell grc)
  ];

  programs = {
    z-lua = {
      enable = true;
      enableAliases = true;
      enableZshIntegration = true;
      enableFishIntegration = config.flags.enableFishShell;
    };

    atuin = {
      enable = true;
      # https://github.com/atuinsh/atuin/commit/1ce88c9d17c6dd66d387b2dfd2544a527a262f3e.
      package = pkgs.nixpkgs-unstable.atuin;
      enableZshIntegration = true;
      enableFishIntegration = config.flags.enableFishShell;
      flags = [ "--disable-up-arrow" ];
      settings = {
        update_check = false;
        style = "compact";
        inline_height = 25;
      };
    };

    fzf = {
      enable = true;
      defaultCommand =
        "fd --type f --hidden --no-ignore --follow --exclude .git";
      enableZshIntegration = true;
      enableFishIntegration = config.flags.enableFishShell;
    };

    starship = {
      enable = true;
      enableZshIntegration = true;
      enableFishIntegration = config.flags.enableFishShell;

      settings = {
        add_newline = false;
        aws.format = "on [$symbol$profile]($style) ";
        gcloud.disabled = true;
        git_status.disabled = false;
        git_branch = {
          truncation_length = 30;
          truncation_symbol = "";
        };
        directory = {
          truncation_length = 1;
        };
        hostname.ssh_only = true;
        username.show_always = false;
        kubernetes = {
          disabled = false;
          context_aliases = {
            "arn:aws:eks:.*:.*:.*/(.*)" = "$1";
          };
        };
        rust.disabled = true;
        nodejs.disabled = true;
        package.disabled = true;
      };
    };

    zsh = {
      enable = true;
      autosuggestion.enable = true;

      history = {
        size = 1024000;
        save = 1024000;
        ignoreDups = true;
        expireDuplicatesFirst = true;
        share = true;
        extended = true;
      };

      shellAliases = shellAliases;

      oh-my-zsh = {
        enable = true;

        plugins = [
          "aws"
          "docker"
          "fd"
          "gh"
          "git"
          "helm"
          "history-substring-search"
          "kubectl"
          "pass"
          "ripgrep"
          "taskwarrior"
          "terraform"
          "tmux"
          "vi-mode"
        ];
      };

      sessionVariables = { _ZL_HYPHEN = 1; };

      initExtra = ''
        # enable alt+l -- to lowercase
        bindkey '^[l' down-case-word

        # vim
        bindkey -M vicmd 'k' history-substring-search-up
        bindkey -M vicmd 'j' history-substring-search-down

        bindkey -M vicmd '^P' history-substring-search-up
        bindkey -M vicmd '^N' history-substring-search-down

        bindkey '^P' history-substring-search-up
        bindkey '^N' history-substring-search-down

        bindkey '^[[A' history-substring-search-up
        bindkey '^[[B' history-substring-search-down

        # enable shift+tab when using vi-mode plugin
        bindkey '^[[Z' reverse-menu-complete

        setopt extendedglob
      '';

      envExtra = ''
        if [[ -d $HOME/bin ]]; then
          export PATH=$PATH:$HOME/bin
        fi

        if [[ -d $GOPATH/bin ]]; then
          export PATH=$PATH:$GOPATH/bin
        fi
      '';
    };

    # https://github.com/nix-community/home-manager/blob/master/modules/programs/fish.nix
    fish = {
      enable = config.flags.enableFishShell;
      shellInit = ''
        set -U fish_term24bit 1
      '';

      interactiveShellInit = ''
        set fish_greeting # Disable greeting
        set fish_vi_key_bindings

        # z.lua -- this is needed for words with hyphens to autocomplete
        set -x _ZL_HYPHEN 1

        if test -d $HOME/bin
            set -gx PATH $PATH $HOME/bin
        end

        if test -d $GOPATH/bin
            set -gx PATH $PATH $GOPATH/bin
        end

        # Git completions; FIXME: remove this once landed in upstream in
        # fish-shell and later when package updated in nixpkgs.
        # https://github.com/fish-shell/fish-shell/pull/10133
        complete -f -c git -n '__fish_git_using_command branch' -l contains -d 'List branches that contain the specified commit' -xa '(__fish_git_commits)'
        complete -f -c git -n '__fish_git_using_command branch' -l no-contains -d 'List branches that don\'t contain the specified commit' -xa '(__fish_git_commits)'

        # https://github.com/remigourdon/dotfiles/commit/733971c51c7dd1050b786c0fdc7ce04bd2661197
        complete --command aws --no-files --arguments '(begin; set --local --export COMP_SHELL fish; set --local --export COMP_LINE (commandline); aws_completer | sed \'s/ $//\'; end)'
      '';
      plugins = with pkgs.fishPlugins; [
        { name = "fzf-fish"; src = fzf-fish.src; }
        { name = "grc"; src = grc.src; }
        { name = "plugin-git"; src = plugin-git.src; }
        { name = "forgit"; src = forgit.src; }
      ];

      shellAliases = shellAliases;
    };
  };
}
