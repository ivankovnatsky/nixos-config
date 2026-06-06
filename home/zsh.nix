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
      mkcd() {
        mkdir -p "$1" && cd "$1"
      }

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

      # direnv hook (direnv installed via Homebrew)
      if (( $+commands[direnv] )); then
        eval "$(direnv hook zsh)"
      fi
    '';

    envExtra = ''
      export GPG_TTY=$(tty)

      if [[ -d $HOME/bin ]]; then
        export PATH=$PATH:$HOME/bin
      fi

      if [[ -d ${config.local.tools.toolsPrefix}/.npm/bin ]]; then
        export PATH=$PATH:${config.local.tools.toolsPrefix}/.npm/bin
      fi

      if [[ -d ${config.local.tools.toolsPrefix}/.bun/bin ]]; then
        export PATH=$PATH:${config.local.tools.toolsPrefix}/.bun/bin
      fi

      # uv tool install directory
      export UV_TOOL_BIN_DIR="${config.local.tools.toolsPrefix}/.local/bin"
      export UV_TOOL_DIR="${config.local.tools.toolsPrefix}/.local/share/uv/tools"

      if [[ -d ${config.local.tools.toolsPrefix}/.local/bin ]]; then
        export PATH=$PATH:${config.local.tools.toolsPrefix}/.local/bin
      fi
${lib.optionalString (config.local.tools.toolsPrefix != config.home.homeDirectory) ''
      # Claude CLI lives in ~/.local/bin (hardcoded in binary)
      if [[ -d $HOME/.local/bin ]]; then
        export PATH=$PATH:$HOME/.local/bin
      fi
''}${lib.optionalString pkgs.stdenv.targetPlatform.isDarwin ''
      # Obsidian CLI
      if [[ -d /Applications/Obsidian.app/Contents/MacOS ]]; then
        export PATH=$PATH:/Applications/Obsidian.app/Contents/MacOS
      fi
''}

    '';
  };
}
