{ config, pkgs, ... }:

{
  imports = [
    ../../modules/flags
    ../../modules/secrets

    ../../home/aichat.nix
    ../../home/firefox-config.nix
    ../../home/git.nix
    ../../home/lsd.nix
    ../../home/mpv.nix
    ../../home/kitty.nix
    ../../home/tmux.nix
    ../../home/shell.nix
    ../../home/direnv.nix
    ../../home/scripts.nix
    ../../home/k9s.nix
    ../../home/terraform.nix
    ../../home/yamlint.nix
    ../../home/yt-dlp.nix

    ../../home/nixvim
    ../../home/nixvim/plugins/gen-nvim
    # ../../home/nixvim/plugins/octo-nvim
  ];
  flags = {
    enableFishShell = true;
    purpose = "work";
    editor = "nvim";
    darkMode = false;
  };
  # This is basically to track you manual installations
  home = {
    file = {
      ".npm-global/.keep".text = ''
        keep
      '';
      ".npmrc".text = ''
        prefix=''${HOME}/.npm-global
        //npm.pkg.github.com/:_authToken=${config.secrets.githubNpmReadPackageToken}
      '';
      ".config/manual".text = ''
        npm install -g @changesets/cli
      '';
    };
    packages = with pkgs; [
      # FIXME: move this to default darwin config
      dust
      fswatch

      watchman
      watchman-make

      # macOS related
      dockutil

      # GUI
      rectangle
      # To use PC mouse with natural scrolling
      nixpkgs-master.mos
      stats

      home-manager

      jq

      magic-wormhole
      rclone

      devbox

      ghorg

      hadolint
      docker-client
      docker-compose

      php
      php83Packages.composer

      nodejs_22

      awscli2
      aws-sso-cli
      aws-sso-creds
      nixpkgs-master.nodePackages.aws-cdk
      ssm-session-manager-plugin
      iam-policy-json-to-terraform

      vault
      teller

      kubectl
      krew
      kustomize
      kubectl-images
      kubectx
      kdash
      kail
      kubernetes-helm
      eks-node-viewer

      fluxcd

      go-jsonnet
      jsonnet-bundler
      mimir
      pre-commit
      commitlint
      nixpkgs-master.nodePackages.eslint
      husky
      cmake

      git-secrets
      delta

      bclm

      (python312.withPackages (ps: with ps; [
        pip
      ]))
    ];

    sessionVariables = {
      EDITOR = config.flags.editor;
      VISUAL = config.flags.editor;
    };
    username = "ivan";
    stateVersion = "24.05";
  };

  programs.nixvim = {
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
          terraformls.enable = true;
          eslint.enable = true;
          tsserver.enable = true;
          phpactor.enable = true;
        };
      };
      none-ls = {
        sources = {
          diagnostics = {
            statix.enable = true;
            hadolint.enable = true;
          };
          formatting = {
            # pretty_php.enable = true;
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
      conform-nvim = {
        formattersByFt = {
          javascript = [
            [
              "prettierd"
              "prettier"
            ]
          ];
          typescript = [
            [
              "prettierd"
              "prettier"
            ]
          ];
          python = [ "black" ];
          lua = [ "stylua" ];
          nix = [ "nixfmt" ];
        };
      };
    };
    extraConfigVim = ''
      augroup commentary
        autocmd FileType terraform setlocal commentstring=#\ %s
        autocmd FileType tf setlocal commentstring=#\ %s
      augroup END
    '';
  };

  programs.home-manager.enable = true;
}
