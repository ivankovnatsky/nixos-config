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
    ../../home/yt-dlp.nix
    ../../home/git.nix
    ../../home/go.nix
    ../../home/lsd.nix

    ../../home/scripts.nix
    ../../home/shell.nix
    ../../home/aichat.nix
    ../../home/tmux.nix
    ../../home/transmission.nix
    ../../home/direnv.nix

    ../../home/nixvim

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
        none-ls = {
          formatting = {
            black = {
              enable = true;
              withArgs = ''
                {
                  extra_args = { "--fast" },
                }
              '';
            };
          };
        };
      };
    };
    extraPlugins = with pkgs.vimPlugins; [
      vim-go
    ];
  };
}
