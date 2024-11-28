{ config, pkgs, ... }:

{
  imports = [
    ../../modules/flags

    ../../home/amethyst.nix
    ../../home/git.nix
    ../../home/jujutsu.nix
    ../../home/lsd.nix
    ../../home/kitty.nix
    ../../home/tmux.nix
    ../../home/shell.nix
    ../../home/starship
    ../../home/direnv.nix
    ../../home/scripts.nix
    ../../home/pass.nix
    ../../home/mpv.nix
    ../../home/yt-dlp.nix
    ../../home/k9s.nix
    ../../home/terraform.nix
    ../../home/yamlint.nix
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
      terminal = "kitty";
      browser = "Google Chrome";
      shortcuts = [
        { key = "0"; app = "Finder"; }
        { key = "1"; app = config.flags.hotkeys.terminal; }
        { key = "2"; app = config.flags.hotkeys.browser; }
        { key = "3"; app = "Slack"; }
        { key = "9"; app = "System Settings"; }
      ];
    };
    apps = {
      vscode.enable = false;
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
      dockutil

      # GUI
      # To use PC mouse with natural scrolling
      nixpkgs-master.mos
      stats
      battery-toolkit
      rectangle

      home-manager

      jq

      magic-wormhole
      rclone

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
      infracost

      kubectl
      krew
      kustomize
      kubectl-images
      kubectx
      kubepug

      kdash

      argocd

      kail
      kubernetes-helm
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

      cloudflared

      pv
      pigz

      poetry

      nodejs

      wget
    ];

    sessionVariables = {
      EDITOR = config.flags.editor;
      VISUAL = config.flags.editor;
    };
    username = "Ivan.Kovnatskyi";
    stateVersion = "24.05";
  };

  programs = {
    # TODO:
    # 1. Make tf file comments italic
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
    ];
  };
}
