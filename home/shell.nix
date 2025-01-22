{ config, lib, pkgs, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin isLinux;

  syncthingHomeDir = if isDarwin then "~/Library/Application\\ Support/Syncthing" else "~/.config/syncthing";

  commonShellAliases = {
    # TODO: add function nix-prefetch-url $url | xargs nix hash to-sri --type sha256
    g = "${pkgs.git}/bin/git";
    cat = "${pkgs.bat}/bin/bat";
    curl = "${pkgs.curlie}/bin/curlie";
    dig = "${pkgs.doggo}/bin/doggo";
    dog = "${pkgs.doggo}/bin/doggo";
    fd = "${pkgs.fd}/bin/fd --hidden --no-ignore";
    ls = "${pkgs.lsd}/bin/lsd --group-dirs first --icon always";
    # Let's not use GNU Coreutils mkdir for now.
    mkdir = "mkdir -p";
    grep = "${pkgs.ripgrep}/bin/rg";
    tree = "${pkgs.lsd}/bin/lsd --tree";
    syncthing = "${pkgs.syncthing}/bin/syncthing serve --no-browser";
    stc = "${pkgs.stc-cli}/bin/stc -homedir ${syncthingHomeDir}";
    vim = "vim -n -c 'set noswapfile'";

    top = if isDarwin then "top -o cpu" else "top";
    image-meta-rm = "exiftool -all= -overwrite_original";
    image-meta-show = "exiftool";
  };

  shellAliases =
    if config.flags.purpose == "home" then commonShellAliases // {
      rclone = "${pkgs.rclone}/bin/rclone -P";
      transmission = "${pkgs.transmission_4}/bin/transmission-remote --list";
      wl-copy = lib.mkIf isLinux "${pkgs.wl-clipboard}/bin/wl-copy -n";
    } else commonShellAliases // {
      # We tenv version manager so pkgs interpolation is not needed.
      tf = "terraform";
      tg = "terragrunt";
      k = "${pkgs.kubectl}/bin/kubectl";
      argocd = "${pkgs.argocd}/bin/argocd --grpc-web";
    };

  # vimPlugin = builtins.fetchurl {
  #   url = "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/vi-mode/vi-mode.plugin.zsh";
  #   sha256 = "sha256:12gsfifj00rlx8nw1zs6cr0g7jxslxhph4mbkkg7fxsyl811c4ad";
  # };
in
{
  home.packages = with pkgs; [
    ripgrep
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
      package = pkgs.atuin;
      enableZshIntegration = true;
      enableFishIntegration = config.flags.enableFishShell;
      flags = [ "--disable-up-arrow" ];
      settings = {
        update_check = false;
        style = "compact";
        inline_height = 25;
        # history_filter = [ ];
      };
    };

    fzf = {
      enable = true;
      defaultCommand =
        "fd --type f --hidden --no-ignore --follow --exclude .git";
      enableZshIntegration = true;
      enableFishIntegration = config.flags.enableFishShell;
    };

    # https://github.com/nix-community/home-manager/blob/master/modules/programs/zsh.nix
    zsh = {
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

      plugins =
        [
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

        # https://fishshell.com/docs/current/interactive.html#vi-mode-commands
        fish_vi_key_bindings

        # z.lua -- this is needed for words with hyphens to autocomplete
        set -x _ZL_HYPHEN 1

        if test -d $HOME/bin
            set -gx PATH $PATH $HOME/bin
        end

        if test -d $GOPATH/bin
            set -gx PATH $PATH $GOPATH/bin
        end

        if test -d $HOME/.npm/bin
            set -gx PATH $PATH $HOME/.npm/bin
        end

        # Git completions; FIXME: remove this once landed in upstream in
        # fish-shell and later when package updated in nixpkgs.
        # https://github.com/fish-shell/fish-shell/pull/10133
        complete -f -c git -n '__fish_git_using_command branch' -l contains -d 'List branches that contain the specified commit' -xa '(__fish_git_commits)'
        complete -f -c git -n '__fish_git_using_command branch' -l no-contains -d 'List branches that don\'t contain the specified commit' -xa '(__fish_git_commits)'

        # https://github.com/remigourdon/dotfiles/commit/733971c51c7dd1050b786c0fdc7ce04bd2661197
        complete --command aws --no-files --arguments '(begin; set --local --export COMP_SHELL fish; set --local --export COMP_LINE (commandline); aws_completer | sed \'s/ $//\'; end)'

        # Add aichat completions for ai
        if command -v aichat >/dev/null
            complete -c ai -w aichat
        end

        # Source ~/.env.fish if exists
        if test -f $HOME/.env.fish
            source $HOME/.env.fish
        end
      '';
      plugins = with pkgs.fishPlugins; [
        { inherit (fzf-fish) name src; }
        { inherit (grc) name src; }
        { inherit (plugin-git) name src; }
        { inherit (forgit) name src; }
        { inherit (autopair) name src; }
        { inherit (git-abbr) name src; }
        { inherit (fish-bd) name src; }
        { inherit (pisces) name src; }
        { inherit (done) name src; }
      ];

      inherit shellAliases;
    };
  };
}
