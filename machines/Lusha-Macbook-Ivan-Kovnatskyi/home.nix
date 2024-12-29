{ config, pkgs, ... }:

{
  imports = [
    ../../modules/flags
    ../../modules/secrets

    ../../home/firefox-config.nix
    ../../home/amethyst.nix
    ../../home/git.nix
    ../../home/jujutsu.nix
    ../../home/lsd.nix
    ../../home/kitty.nix
    ../../home/tmux.nix
    ../../home/go.nix
    ../../home/shell.nix
    ../../home/aichat.nix
    ../../home/ghostty.nix
    ../../home/nushell.nix
    ../../home/starship
    ../../home/direnv.nix
    ../../home/scripts.nix
    ../../home/pgcli.nix
    ../../home/pass.nix
    ../../home/mpv.nix
    ../../home/yt-dlp.nix
    ../../home/k9s.nix
    ../../home/terraform.nix
    ../../home/yamlint.nix
    ../../home/zed
    ../../home/vscode.nix
    ../../home/syncthing.nix

    # ../../home/launchd-services.nix

    ../../home/hammerspoon

    ../../home/nixvim
    ../../home/nixvim/plugins/gen-nvim
    ../../home/nixvim/plugins/nvim-jenkinsfile-linter
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
      nixpkgs-master.mos
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
      nixpkgs-master.nodePackages.aws-cdk
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
        avante.enable = true;

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
