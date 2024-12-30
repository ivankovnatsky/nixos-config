{ config, pkgs, ... }:

{
  imports = [
    # ../../home/launchd-services.nix
    ../../home/aichat.nix
    ../../home/amethyst.nix
    ../../home/direnv.nix
    ../../home/firefox-config.nix
    ../../home/ghostty.nix
    ../../home/git.nix
    ../../home/go.nix
    ../../home/hammerspoon
    ../../home/jujutsu.nix
    ../../home/k9s.nix
    ../../home/kitty.nix
    ../../home/lsd.nix
    ../../home/mpv.nix
    ../../home/nixvim
    ../../home/nixvim/plugins/gen-nvim
    ../../home/nixvim/plugins/nvim-jenkinsfile-linter
    ../../home/nushell.nix
    ../../home/pass.nix
    ../../home/pgcli.nix
    ../../home/scripts.nix
    ../../home/shell.nix
    ../../home/starship
    ../../home/syncthing.nix
    ../../home/terraform.nix
    ../../home/tmux.nix
    ../../home/vscode.nix
    ../../home/yamlint.nix
    ../../home/yt-dlp.nix
    ../../home/zed
    ../../modules/flags
    ../../modules/secrets
  ];
  flags = {
    enableFishShell = true;
    purpose = "work";
    editor = "nvim";
    darkMode = true;
    hotkeys = {
      terminal = "Ghostty";
      browser = "Google Chrome";
      shortcuts = [
        { key = "0"; app = "Finder"; }
        { key = "1"; app = config.flags.hotkeys.terminal; }
        { key = "2"; app = config.flags.hotkeys.browser; }
        { key = "3"; app = "Slack"; }
        { key = "4"; app = "Firefox"; }
        { key = "5"; app = "Cursor"; }
        { key = "6"; app = "Visual Studio Code"; }
        { key = "7"; app = "Zed"; }
        { key = "9"; app = "System Settings"; }
      ];
    };
    apps = {
      vscode.enable = true;
    };
  };
  home = {
    packages = with pkgs; [
      defaultbrowser
      dust
      genpass

      watchman
      watchman-make

      # macOS related
      # CLI
      dockutil

      # GUI
      # To use PC mouse with natural scrolling
      mos
      stats
      battery-toolkit
      rectangle
      maccy

      home-manager

      jq

      magic-wormhole
      rclone
      pv
      pigz

      devbox

      ghorg

      hadolint
      docker-client
      docker-compose

      awscli2
      aws-sso-cli
      aws-sso-creds
      nodePackages.aws-cdk
      ssm-session-manager-plugin
      iam-policy-json-to-terraform

      terraformer
      terragrunt-atlantis-config
      hclfmt
      infracost

      kubectl
      kubecolor
      krew
      kustomize
      kubectl-images
      kubectx
      kubepug

      kdash

      argocd

      kail
      (wrapHelm kubernetes-helm {
        plugins = with pkgs.kubernetes-helmPlugins; [
          helm-secrets
        ];
      })
      eks-node-viewer

      pre-commit

      gitleaks
      delta

      (python312.withPackages (ps: with ps; [
        pip
      ]))

      exiftool

      vault

      postgresql
      mariadb
      mongosh

      cloudflared

      poetry

      nodejs

      wget

      ghostty
      coreutils
    ];

    sessionVariables = {
      EDITOR = config.flags.editor;
      VISUAL = config.flags.editor;

      ANTHROPIC_API_KEY = "${config.secrets.anthropicApiKey}";
    };
    username = "Ivan.Kovnatskyi";
    stateVersion = "24.05";
  };

  programs = {
    # TODO:
    # 1. Make tf file comments italic
    # Add nushell support
    nixvim = {
      editorconfig.enable = true;
      plugins = {
        # Enable when it will be update to at least this version:
        # https://github.com/pwntester/octo.nvim/commit/b4923dc97555c64236c4535b2adf75c74c00caca
        octo.enable = true;
        lint = {
          lintersByFt = {
            terraform = [ "tflint" ];
          };
        };
        lsp = {
          servers = {
            bashls.enable = true;
            pyright.enable = true;
            terraformls.enable = true;
            # groovyls.enable = true;
          };
        };
        none-ls = {
          sources = {
            diagnostics = {
              statix.enable = true;
              hadolint.enable = true;
            };
            formatting = {
              # terragrunt_fmt.enable = true;
              # terragrunt_validate.enable = true;
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
        conform-nvim = {
          settings.formatters_by_ft = {
            python = [ "black" ];
            lua = [ "stylua" ];
            nix = [ "nixfmt" ];
          };
        };
        # https://github.com/yetone/avante.nvim
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

        # FIXME: Figure out suitable key for the completion, when you need to
        # override cmp plugins.
        copilot-vim.enable = true;
      };
      extraPlugins = with pkgs.vimPlugins; [
        Jenkinsfile-vim-syntax
      ];
      extraConfigVim = ''
        augroup commentary
          autocmd FileType terraform setlocal commentstring=#\ %s
          autocmd FileType tf setlocal commentstring=#\ %s
        augroup END
      '';
    };
    home-manager.enable = true;
    # https://github.com/nix-community/home-manager/blob/master/modules/programs/gh.nix#L115
    gh.extensions = with pkgs; [
      gh-token
      gh-copilot
    ];
  };
}
