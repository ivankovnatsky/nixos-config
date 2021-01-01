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
      };

      oh-my-zsh = {
        enable = true;

        plugins = [
          "git"
          "vi-mode"
          "aws"
          "command-not-found"
          "fd"
          "ripgrep"
          "git"
          "terraform"
          "docker"
          "vault"
          "kops"
          "helm"
          "tmux"
          "kubectl"
          "vi-mode"
          "history-substring-search"
        ];
      };

      profileExtra = ''
        export PATH="$HOME/.bin:$PATH"
      '';

      envExtra = ''
        source ~/.env || touch ~/.env
      '';

      sessionVariables = { AWS_VAULT_BACKEND = "pass"; };

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
      '';

    };
  };
}
