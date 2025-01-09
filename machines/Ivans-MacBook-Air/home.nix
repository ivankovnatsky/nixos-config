{ config, pkgs, ... }:

{
  imports = [
    ../../home/aichat.nix
    ../../home/amethyst.nix
    ../../home/direnv.nix
    ../../home/firefox-config.nix
    ../../home/ghostty.nix
    ../../home/git.nix
    ../../home/go.nix
    ../../home/hammerspoon
    ../../home/launchd-services/dark-mode-kitty
    ../../home/lsd.nix
    ../../home/mpv.nix
    ../../home/nixvim
    ../../home/nixvim/plugins/avante
    ../../home/npm.nix
    ../../home/scripts.nix
    ../../home/shell.nix
    ../../home/starship
    ../../home/syncthing.nix
    ../../home/taskwarrior.nix
    ../../home/tmux.nix
    ../../home/transmission.nix
    ../../home/vscode.nix
    ../../home/yt-dlp.nix
    ../../home/zed
    ../../modules/flags
    ../../modules/secrets
  ];
  flags = {
    enableFishShell = true;
    purpose = "home";
    editor = "nvim";
    darkMode = true;
    hotkeys = {
      terminal = "Ghostty";
      browser = "Safari";
      shortcuts = [
        { key = "0"; app = "Finder"; }
        { key = "1"; app = config.flags.hotkeys.terminal; }
        { key = "2"; app = config.flags.hotkeys.browser; }
        { key = "4"; app = "Cursor"; }
        { key = "5"; app = "Visual Studio Code"; }
        { key = "6"; app = "Zed"; }
        { key = "9"; app = "System Settings"; }
      ];
    };
    apps = {
      vscode.enable = true;
    };
  };
  home = {
    packages = with pkgs; [
      home-manager
      zsh-forgit

      rclone
      pigz

      aria2
      wget
      # FIXME: Fails to install on current nixpkgs-unstable
      # nodePackages.webtorrent-cli
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

      # FIXME: Fails to install on current nixpkgs-unstable
      # bitwarden-cli
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
      mos

      battery-toolkit

      username
      backup-home

      watchman
      watchman-make

      (python312.withPackages (ps: with ps; [
        grip
      ]))

      nodejs

      ghostty

      parallel

      imagemagick
    ];
    sessionVariables = {
      EDITOR = config.flags.editor;
      ANTHROPIC_API_KEY = "${config.secrets.anthropicApiKey}";
      OPENAI_API_KEY = "${config.secrets.openaiApiKey}";
    };
    file.".config/manual".text = ''
      npm --global install webtorrent-cli
    '';
  };
  programs = {
    nixvim = {
      plugins = {
        octo.enable = true;
        lsp = {
          servers = {
            eslint.enable = true;
            ts_ls.enable = true;
            tinymist.enable = true;
            pyright.enable = true;
            gopls.enable = true;
            rust_analyzer = {
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
                settings = ''
                  {
                    extra_args = { "--fast" };
                  }
                '';
              };
            };
          };
        };
        copilot-vim.enable = true;
      };
      extraPlugins = with pkgs.vimPlugins; [
        vim-go
      ];
    };
  };
}
