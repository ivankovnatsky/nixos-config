{ config, pkgs, ... }:

{
  imports = [
    ../../home/amethyst.nix
    ../../home/firefox-config.nix
    ../../home/mpv.nix
    ../../home/yt-dlp.nix
    ../../home/git.nix
    ../../home/go.nix
    ../../home/lsd.nix

    ../../home/scripts.nix
    ../../home/shell.nix
    ../../home/starship.nix
    ../../home/aichat.nix
    ../../home/tmux.nix
    ../../home/transmission.nix
    ../../home/direnv.nix

    ../../home/nixvim

    ../../modules/flags
    ../../modules/secrets
  ];
  flags = {
    enableFishShell = true;
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
      wget
      nodePackages.webtorrent-cli
      exiftool
      syncthing
      bat
      erdtree
      fzf
      ripgrep
      delta
      nixpkgs-fmt
      magic-wormhole
      typst
      typstfmt
      du-dust
      duf
      genpass
      fswatch

      bitwarden-cli
      jq

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

      battery-toolkit

      username

      watchman
      watchman-make

      (python312.withPackages (ps: with ps; [
        grip
      ]))
    ];
    sessionVariables = {
      EDITOR = config.flags.editor;
    };
    stateVersion = "22.05";
  };
  programs = {
    nixvim = {
      plugins = {
        octo.enable = true;
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
          sources = {
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
  };
}
