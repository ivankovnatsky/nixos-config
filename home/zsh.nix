{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin isLinux;

  syncthingHomeDir =
    if isDarwin then "~/Library/Application\\ Support/Syncthing" else "~/.config/syncthing";

  commonShellAliases = {
    # TODO: add function nix-prefetch-url $url | xargs nix hash to-sri --type sha256
    g = "${pkgs.git}/bin/git";
    erd = "${pkgs.erdtree}/bin/erd --color auto --human -L 1 --layout inverted --icons --long --hidden";
    # Let's not use GNU Coreutils mkdir for now.
    mkdir = "mkdir -p";
    less = "less -RS";
    syncthing = "${pkgs.syncthing}/bin/syncthing serve --no-browser";
    stc = "${pkgs.stc-cli}/bin/stc -homedir ${syncthingHomeDir}";
  };

  shellAliases =
    if config.flags.purpose == "home" then
      commonShellAliases
      // {
        rclone = "${pkgs.rclone}/bin/rclone -P";
        wl-copy = lib.mkIf isLinux "${pkgs.wl-clipboard}/bin/wl-copy -n";
      }
    else
      commonShellAliases
      // {
        # We tenv version manager so pkgs interpolation is not needed.
        tf = "tofu";
        tg = "terragrunt";
        k = "${pkgs.kubectl}/bin/kubectl";
        argocd = "${pkgs.argocd}/bin/argocd --grpc-web";
      };

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
      # Disable focus reporting mode to prevent [I and [O escape sequences
      # https://github.com/anthropics/claude-code/issues/10375
      printf '\e[?1004l'

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

      # Add ai completions
      if (( $+commands[aichat] )); then
        compdef ai=aichat
      fi
    '';

    envExtra = ''
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
