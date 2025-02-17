{ config, pkgs, ... }:

{
  imports = [
    ../../home/aichat.nix
    ../../home/amethyst.nix
    ../../home/direnv.nix
    ../../home/firefox-config.nix
    ../../home/fish-ai.nix
    ../../home/ghostty.nix
    ../../home/git.nix
    ../../home/go.nix
    ../../home/hammerspoon
    ../../home/lsd.nix
    ../../home/mpv.nix
    ../../home/nixvim
    ../../home/nixvim/plugins/avante
    ../../home/pass.nix
    ../../home/scripts.nix
    ../../home/shell.nix
    ../../home/starship
    ../../home/syncthing.nix
    ../../home/taskwarrior.nix
    ../../home/tmux.nix
    ../../home/vscode.nix
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
        {
          key = "1";
          app = "Finder";
        }
        {
          key = "2";
          app = config.flags.hotkeys.terminal;
        }
        {
          key = "3";
          app = config.flags.hotkeys.browser;
        }
        {
          key = "9";
          app = "System Settings";
        }
      ];
    };
    apps = {
      vscode.enable = false;
    };
  };
  home = {
    packages = with pkgs; [
      # username # Installed as flake  # FIXME: correct hash256
      (python312.withPackages (ps: with ps; [ grip ]))
      aria2
      bat
      cargo
      coconutbattery # macOS: Battery
      delta
      du-dust
      duf
      fish-ai # Local overlay
      fzf
      genpass
      ghostty
      home-manager
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
      watchman
      watchman-make
      wget
      yt-dlp
      zsh-forgit
    ];
    sessionVariables = {
      EDITOR = config.flags.editor;
      ANTHROPIC_API_KEY = "${config.secrets.anthropicApiKey}";
      OPENAI_API_KEY = "${config.secrets.openaiApiKey}";
    };
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
        # copilot-vim.enable = true;
      };
      extraPlugins = with pkgs.vimPlugins; [
        vim-go
      ];
    };
  };
}
