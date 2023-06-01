# vim:filetype=nix
{ pkgs, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin;

  syncthingHomeDir = if isDarwin then "~/Library/Application\\ Support/Syncthing" else "~/.config/syncthing";

in
{
  home.packages = with pkgs; [
    exa
    fd
  ];

  programs = {
    z-lua = {
      enable = true;
      enableAliases = true;
      enableZshIntegration = true;
    };

    fzf = {
      enable = true;
      defaultCommand =
        "fd --type f --hidden --no-ignore --follow --exclude .git";
      enableZshIntegration = true;
    };

    starship = {
      enable = true;
      enableZshIntegration = true;

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

      history = {
        size = 1024000;
        save = 1024000;
        ignoreDups = true;
        expireDuplicatesFirst = true;
        share = true;
        extended = true;
      };

      shellAliases = {
        ls = "exa --group-directories-first --group --icons";
        tree = "ls --tree";
        cat = "bat";
        grep = "rg";
        rclone = "rclone -P";
        wl-copy = "wl-copy -n";
        stc = "stc -homedir ${syncthingHomeDir}";
      };

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
        if [[ -d /opt/homebrew/bin ]]; then
          export PATH=$PATH:/opt/homebrew/bin
        fi

        if [[ -d $HOME/bin ]]; then
          export PATH=$PATH:$HOME/bin
        fi
      '';
    };
  };
}
