{ ... }:

{
  programs = {
    zsh = {
      enable = true;

      ohMyZsh = {
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
          "z"
          "vi-mode"
          "history-substring-search"
        ];
      };

      shellInit = ''
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --no-ignore --follow --exclude .git'
        export ZSH_DISABLE_COMPFIX=true

        export PATH="$HOME/.tfenv/bin:$PATH"
        export PATH="$HOME/.tgenv/bin:$PATH"

        # Uncomment the following line to use case-sensitive completion.
        CASE_SENSITIVE="true"

        # Plugin specific settings
        # disable showing up aws profile info
        SHOW_AWS_PROMPT=false

        source ~/.env || touch ~/.env

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

        eval "$(starship init zsh)"
      '';
    };
  };
}
