{ config, pkgs, ... }:

{
  imports = [
    ../../modules/flags
    ../../modules/secrets

    ../../home/firefox-config.nix
    ../../home/git.nix
    ../../home/lsd.nix
    ../../home/mpv.nix
    ../../home/tmux.nix
    ../../home/shell.nix
    ../../home/direnv.nix
    ../../home/scripts.nix
    ../../home/k9s.nix
    ../../home/terraform.nix

    ../../home/nixvim
  ];
  flags = {
    enableFishShell = true;
    purpose = "work";
    editor = "nvim";
    darkMode = false;
  };
  # This is basically to track you manual installations
  home.file = {
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
  home.packages = with pkgs; [
    # FIXME: move this to default darwin config
    dust
    fswatch
    rectangle
    # To use PC mouse with natural scrolling
    nixpkgs-master.mos
    stats

    home-manager

    jq

    magic-wormhole

    ghorg

    docker-client
    docker-compose

    php
    php83Packages.composer

    nodejs

    awscli2
    aws-sso-cli
    aws-sso-creds
    nixpkgs-master.nodePackages.aws-cdk
    ssm-session-manager-plugin

    vault
    teller

    kubectl
    kubectl-images
    kubectx
    kdash
    kail
    eks-node-viewer

    fluxcd

    go-jsonnet
    jsonnet-bundler
    mimir
    pre-commit
    commitlint
    husky
    cmake

    yamllint
  ];
  programs.nixvim = {
    editorconfig.enable = true;
    plugins = {
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
            yamllint.enable = true;
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
            prettier = {
              enable = true;
              disableTsServerFormatter = true;
              withArgs = ''
                {
                  extra_args = { "--no-semi", "--single-quote" },
                }
              '';
            };
            yamlfmt.enable = true;
            yamlfix.enable = true;
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
          yaml = [
            "yamllint"
            "yamlfmt"
          ];
        };
      };
    };
  };

  home.sessionVariables = {
    EDITOR = config.flags.editor;
    VISUAL = config.flags.editor;
  };
  home.username = "ivan";
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;
}
