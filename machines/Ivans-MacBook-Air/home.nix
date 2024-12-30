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
    ../../home/kitty.nix
    ../../home/lsd.nix
    ../../home/mpv.nix
    ../../home/nixvim
    ../../home/npm.nix
    ../../home/scripts.nix
    ../../home/shell.nix
    ../../home/starship
    ../../home/syncthing.nix
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
    stateVersion = "22.05";
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
        # https://github.com/yetone/avante.nvim?tab=readme-ov-file#default-setup-configuration
        # https://github.com/nix-community/nixvim/blob/f4b0b81ef9eb4e37e75f32caf1f02d5501594811/tests/test-sources/plugins/by-name/avante/default.nix#L3
        avante = {
          enable = true;
          settings = {
            debug = false;
            provider = "claude";
            auto_suggestions_provider = "claude";
            tokenizer = "tiktoken";
            system_prompt = ''
              You are an excellent programming expert.
            '';
            openai = {
              endpoint = "https://api.openai.com/v1";
              model = "gpt-4o";
              timeout = 30000;
              temperature = 0;
              max_tokens = 4096;
            };
            copilot = {
              endpoint = "https://api.githubcopilot.com";
              model = "gpt-4o-2024-05-13";
              proxy = null;
              allow_insecure = false;
              timeout = 30000;
              temperature = 0;
              max_tokens = 4096;
            };
            claude = {
              endpoint = "https://api.anthropic.com";
              model = "claude-3-5-sonnet-20240620";
              timeout = 30000;
              temperature = 0;
              max_tokens = 8000;
            };
            behaviour = {
              auto_suggestions = false;
              auto_set_highlight_group = true;
              auto_set_keymaps = true;
              auto_apply_diff_after_generation = false;
              support_paste_from_clipboard = false;
            };
            mappings = {
              sidebar = {
                # Tab is currently used for Github Copilot.
                switch_windows = "<C-k>";
                reverse_switch_windows = "<C-j>";
              };
            };
            diff = {
              autojump = true;
            };
            hints = {
              enabled = true;
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
