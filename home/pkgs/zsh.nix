{ ... }:

{
  programs = {
    z-lua = {
      enable = true;
      enableAliases = true;
      enableZshIntegration = true;
    };

    starship = {
      enable = true;
      enableZshIntegration = true;

      settings = {
        add_newline = false;
        line_break.disabled = true;
        aws.disabled = true;
        git_status.disabled = false;
        hostname.ssh_only = true;
        username.show_always = false;
      };
    };

    fzf = {
      enable = true;
      defaultCommand =
        "fd --type f --hidden --no-ignore --follow --exclude .git";
      enableZshIntegration = true;
    };

    zsh = {
      enable = true;

      history = {
        size = 102400;
        save = 102400;
        ignoreDups = true;
        expireDuplicatesFirst = true;
        share = true;
        extended = true;
      };

      shellAliases = {
        ls = "exa --group-directories-first --group";
        tree = "exa --tree";
      };

      oh-my-zsh = {
        enable = true;

        plugins = [
          "aws"
          "command-not-found"
          "docker"
          "fd"
          "git"
          "helm"
          "history-substring-search"
          "kubectl"
          "ripgrep"
          "terraform"
          "tmux"
          "vi-mode"
        ];
      };

      profileExtra = ''
        export PATH="$HOME/.bin:$PATH"
      '';

      envExtra = "";

      sessionVariables = {
        AWS_VAULT_BACKEND = "pass";
        _ZL_HYPHEN = 1;
      };

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
    };
  };
}
