{
  config,
  lib,
  pkgs,
  ...
}:

let
  shellAliases = import ./aliases.nix { inherit config lib pkgs; };

in
# vimPlugin = builtins.fetchurl {
#   url = "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/vi-mode/vi-mode.plugin.zsh";
#   sha256 = "sha256:12gsfifj00rlx8nw1zs6cr0g7jxslxhph4mbkkg7fxsyl811c4ad";
# };
{
  home.packages = with pkgs; [
    zsh-forgit
  ];

  # https://github.com/nix-community/home-manager/blob/master/modules/programs/zsh.nix
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;
    autocd = true;

    history = {
      size = 1024000;
      save = 1024000;
      ignoreDups = true;
      expireDuplicatesFirst = true;
      share = true;
      extended = true;
    };

    plugins = [
      # {
      #   name = "zsh-vi-mode";
      #   src = pkgs.fetchFromGitHub {
      #     owner = "jeffreytse";
      #     repo = "zsh-vi-mode";
      #     rev = "v0.11.0";
      #     sha256 = "sha256-xbchXJTFWeABTwq6h4KWLh+EvydDrDzcY9AQVK65RS8=";
      #   };
      # }
    ];
    # initExtra = ''
    #   source ${vimPlugin}
    # '';

    inherit shellAliases;

    sessionVariables = {
      _ZL_HYPHEN = 1;
    };

    initContent = ''
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
      setopt IGNORE_EOF

      # Add ai completions
      if (( $+commands[aichat] )); then
        compdef ai=aichat
      fi
    '';

    envExtra = ''
      export GPG_TTY=$(tty)

      if [[ -d $HOME/bin ]]; then
        export PATH=$PATH:$HOME/bin
      fi

      if [[ -d $GOPATH/bin ]]; then
        export PATH=$PATH:$GOPATH/bin
      fi

      if [[ -d $HOME/.npm/bin ]]; then
        export PATH=$PATH:$HOME/.npm/bin
      fi

      if [[ -d $HOME/.bun/bin ]]; then
        export PATH=$PATH:$HOME/.bun/bin
      fi

      if [[ -d $HOME/.local/bin ]]; then
        export PATH=$PATH:$HOME/.local/bin
      fi

    '';
  };
}
