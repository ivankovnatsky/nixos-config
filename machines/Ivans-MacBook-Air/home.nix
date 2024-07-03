{ config, pkgs, ... }:

let
  # vimPlugin = builtins.fetchurl {
  #   url = "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/vi-mode/vi-mode.plugin.zsh";
  #   sha256 = "sha256:12gsfifj00rlx8nw1zs6cr0g7jxslxhph4mbkkg7fxsyl811c4ad";
  # };
  inherit (pkgs.stdenv.targetPlatform) isDarwin;
in
{
  imports = [
    ../../home/firefox-config.nix
    ../../home/mpv.nix
    ../../home/git.nix
    ../../home/go.nix
    ../../home/lsd.nix
    ../../home/nixvim
    ../../home/scripts.nix
    ../../home/aichat.nix
    ../../home/tmux.nix
    ../../home/transmission.nix
    ../../home/direnv.nix

    ../../modules/flags
    ../../modules/secrets
  ];
  flags = {
    purpose = "home";
    editor = "nvim";
    darkMode = false;
  };
  home = {
    packages = with pkgs; [
      home-manager
      zsh-forgit
      rclone
      aria2
      nodePackages.webtorrent-cli
      exiftool
      syncthing
      yt-dlp
      bat
      fzf
      ripgrep
      delta
      nixpkgs-fmt
      magic-wormhole
      typst
      typstfmt
      du-dust
      genpass
      fswatch

      bitwarden-cli
      jq

      nixpkgs-master.ollama

      rust-analyzer
      cargo
      rustc

      ks

      # macOS specific
      rectangle
      coconutbattery
      stats
      # To use PC mouse with natural scrolling
      nixpkgs-master.mos

      username
    ];
    sessionVariables = {
      EDITOR = config.flags.editor;
    };
    stateVersion = "22.05";
  };
  programs = {
    nixvim = {
      plugins = {
        lsp = {
          servers = {
            eslint.enable = true;
            tsserver.enable = true;
            typst-lsp.enable = true;
            pyright.enable = true;
            gopls.enable = true;
            rust-analyzer = {
              enable = true;
              installCargo = true;
              installRustc = true;
            };
          };
        };
      };
      extraPlugins = with pkgs.vimPlugins; [
        vim-go
        tokyonight-nvim
      ];
    };
    z-lua = {
      enable = true;
      enableZshIntegration = true;
    };
    atuin = {
      package = pkgs.nixpkgs-master.atuin;
      enable = true;
      enableZshIntegration = true;
      flags = [ "--disable-up-arrow" ];
      settings = {
        update_check = false;
        style = "compact";
        inline_height = 25;
        # history_filter = [ ];
      };
    };
    zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      historySubstringSearch.enable = true;
      autocd = true;
      shellAliases = {
        top = if isDarwin then "top -o cpu" else "top";
        g = "git";
        rm-image-meta = "exiftool -all= -overwrite_original";
        show-image-meta = "exiftool";
        ls = "${pkgs.lsd}/bin/lsd --group-dirs first --icon always";
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
      sessionVariables = { _ZL_HYPHEN = 1; };
    };
    starship = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
