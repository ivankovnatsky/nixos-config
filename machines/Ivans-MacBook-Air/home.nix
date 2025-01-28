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
    ../../home/lsd.nix
    ../../home/mpv.nix
    ../../home/nixvim
    ../../home/nixvim/plugins/avante
    ../../home/npm.nix
    ../../home/pass.nix
    ../../home/scripts.nix
    ../../home/shell.nix
    ../../home/starship
    ../../home/syncthing.nix
    ../../home/taskwarrior.nix
    ../../home/tmux.nix
    ../../home/transmission.nix
    ../../home/vscode.nix
    ../../home/yt-dlp.nix
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
        { key = "1"; app = "Finder"; }
        { key = "2"; app = config.flags.hotkeys.terminal; }
        { key = "3"; app = config.flags.hotkeys.browser; }
        { key = "4"; app = "Cursor"; }
        { key = "9"; app = "System Settings"; }
      ];
    };
    apps = {
      vscode.enable = false;
    };
  };
  home = {
    packages = with pkgs; [
      # bitwarden-cli  # FIXME: Fails to install on current nixpkgs-unstable
      # nodePackages.webtorrent-cli  # FIXME: Fails to install on current nixpkgs-unstable
      (python312.withPackages (ps: with ps; [ grip ]))
      aria2
      backup-home # Installed as flake
      bat
      battery-toolkit # macOS: Battery
      cargo
      coconutbattery # macOS: Battery
      delta
      du-dust
      duf
      erdtree
      exiftool
      fzf
      genpass
      ghostty
      home-manager
      imagemagick
      jq
      ks
      magic-wormhole
      mos # macOS: System stats
      nixfmt-rfc-style
      nodejs
      parallel
      pigz
      rclone
      rectangle # macOS: Window manager
      ripgrep
      rust-analyzer
      rustc
      stats # macOS: System stats
      syncthing
      typst
      typstfmt
      username # Installed as flake
      watchman
      watchman-make
      wget
      zsh-forgit
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
