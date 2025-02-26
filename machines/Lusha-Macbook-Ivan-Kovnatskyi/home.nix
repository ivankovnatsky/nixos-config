{ config, pkgs, ... }:

{
  imports = [
    # ../../home/nixvim/plugins/nvim-jenkinsfile-linter
    ../../home/aichat-server.nix
    ../../home/aichat.nix
    ../../home/amethyst.nix
    ../../home/bat.nix
    ../../home/direnv.nix
    ../../home/firefox-config.nix
    ../../home/fish-ai.nix
    ../../home/ghorg.nix
    ../../home/ghostty.nix
    ../../home/git.nix
    ../../home/go.nix
    ../../home/hammerspoon
    ../../home/jujutsu.nix
    ../../home/k9s.nix
    ../../home/launchd-services/dark-mode-kitty
    ../../home/lsd.nix
    ../../home/mpv.nix
    ../../home/nixvim
    ../../home/nixvim/plugins/avante
    ../../home/nixvim/plugins/codeium
    ../../home/nixvim/plugins/gen-nvim
    ../../home/nixvim/plugins/copilot-lua
    ../../home/npm.nix
    ../../home/nushell.nix
    ../../home/pass.nix
    ../../home/pgcli.nix
    ../../home/pyenv.nix
    ../../home/scripts.nix
    ../../home/shell.nix
    ../../home/starship
    ../../home/syncthing.nix
    ../../home/terraform.nix
    ../../home/thefuck.nix
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
          key = "4";
          app = "Google Chrome";
        }
        {
          key = "5";
          app = "Firefox";
        }
        {
          key = "6";
          app = "Slack";
        }
        {
          key = "7";
          app = "Cursor";
        }
        {
          key = "9";
          app = "System Settings";
        }
      ];
    };
    apps = {
      vscode.enable = true;
    };
  };
  home = {
    file.".config/manual".text = ''
      npm --global install \
        npm-groovy-lint \
        @anthropic-ai/claude-code
    '';
    packages = with pkgs; [
      (wrapHelm kubernetes-helm { plugins = with pkgs.kubernetes-helmPlugins; [ helm-secrets ]; })
      argocd
      aws-sso-cli
      aws-sso-creds
      awscli2
      backup-home
      cloudflared
      coreutils
      defaultbrowser
      delta
      devbox
      docker-client
      docker-compose
      dockutil # macOS related CLI
      duf
      dust
      eks-node-viewer
      exiftool
      genpass
      ggh
      ghorg
      ghostty
      gitleaks
      gum
      hadolint
      hclfmt
      home-manager
      iam-policy-json-to-terraform
      imagemagick
      infracost
      jq
      k8sgpt
      kail
      kdash
      krew
      kubecolor
      kubectl
      kubectl-images
      kubectl-view-secret
      kubectx
      kubepug
      kustomize
      maccy # Clipboard manager
      magic-wormhole
      mariadb
      mongosh
      mos # To use PC mouse with natural scrolling GUI
      mycli
      nixfmt-rfc-style
      nodePackages.aws-cdk
      nodejs
      parallel
      pigz
      poetry
      postgresql
      pre-commit
      pv
      pyenv-nix-install
      rabbitmq-server # Needed for the CLI
      rabbitmqadmin-ng # Overlay
      rclone
      rectangle # Window manager
      sesh
      sshpass
      ssm-session-manager-plugin
      stats # To show CPU, RAM, etc. usage in the menu bar
      terraformer
      terragrunt-atlantis-config
      vault
      watchman
      watchman-make
      wget
      yq
      zoxide
    ];

    sessionVariables = {
      EDITOR = config.flags.editor;
      VISUAL = config.flags.editor;
      ANTHROPIC_API_KEY = "${config.secrets.anthropicApiKey}";
    };
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
        notify.enable = true;
        lint = {
          lintersByFt = {
            terraform = [ "tflint" ];
            text = [ "vale" ];
            json = [ "jsonlint" ];
            markdown = [ "vale" ];
            dockerfile = [ "hadolint" ];
          };
        };
        lsp = {
          servers = {
            bashls.enable = true;
            pyright.enable = true;
            terraformls.enable = true;
            # terraform_lsp.enable = true;
            nushell.enable = true;
            # groovyls.enable = true;
          };
        };
        none-ls = {
          sources = {
            diagnostics = {
              statix.enable = true;
              hadolint.enable = true;
              # terraform_validate.enable = true;
              terragrunt_validate.enable = true;
              # npm_groovy_lint.enable = true;
            };
            formatting = {
              terragrunt_fmt.enable = true;
              # npm_groovy_lint.enable = true;
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
          };
        };
        # FIXME: Figure out suitable key for the completion, when you need to
        # override cmp plugins.
        # FIXME: allowUnfree
        # copilot-vim.enable = true;
        # https://github.com/nix-community/nixvim/discussions/540
        # https://github.com/nix-community/nixvim/discussions/2054
        treesitter = {
          languageRegister.nu = "nu";
          grammarPackages = with pkgs; [
            tree-sitter-grammars.tree-sitter-nu
          ];
        };
      };
      extraPlugins = with pkgs; [
        vimPlugins.Jenkinsfile-vim-syntax

        # This was needed to enable highlighting in Telescope window
        vimPlugins.nvim-treesitter-parsers.terraform

        vimPlugins.nvim-nu
        tree-sitter-grammars.tree-sitter-nu
      ];
      extraConfigVim = ''
        augroup commentary
          autocmd FileType terraform setlocal commentstring=#\ %s
          autocmd FileType tf setlocal commentstring=#\ %s
        augroup END
      '';
      # ```console
      # evaluation warning: Passing a string for `home-manager.users."Ivan.Kovnatskyi".programs.nixvim.extraFiles."queries/nu/highlights.scm"' is deprecated, use submodule instead. Definitions:
      #                     - In `/nix/store/gg4g68iljc7w1z8si639fcjxs4xvfwd5-source/machines/Lusha-Macbook-Ivan-Kovnatskyi/home.nix':
      #                         ''
      #                           ;;; ---
      #                           ;;; keywords
      #                           [
      #                               "def"
      #                         ...
      # evaluation warning: Passing a string for `home-manager.users."Ivan.Kovnatskyi".programs.nixvim.extraFiles."queries/nu/injections.scm"' is deprecated, use submodule instead. Definitions:
      #                     - In `/nix/store/gg4g68iljc7w1z8si639fcjxs4xvfwd5-source/machines/Lusha-Macbook-Ivan-Kovnatskyi/home.nix':
      #                         ''
      #                           ((comment) @injection.content
      #                            (#set! injection.language "comment"))''
      # ```
      # extraFiles = {
      #   "queries/nu/highlights.scm" = builtins.readFile "${pkgs.tree-sitter-grammars.tree-sitter-nu}/queries/nu/highlights.scm";
      #   "queries/nu/injections.scm" = builtins.readFile "${pkgs.tree-sitter-grammars.tree-sitter-nu}/queries/nu/injections.scm";
      # };
      extraConfigLua = ''
        local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
        parser_config.nu = {
          filetype = "nu",
        }

        require'nu'.setup{
          use_lsp_features = true, -- requires https://github.com/jose-elias-alvarez/null-ls.nvim
          -- lsp_feature: all_cmd_names is the source for the cmd name completion.
          -- It can be
          --  * a string, which is evaluated by nushell and the returned list is the source for completions (requires plenary.nvim)
          --  * a list, which is the direct source for completions (e.G. all_cmd_names = {"echo", "to csv", ...})
          --  * a function, returning a list of strings and the return value is used as the source for completions
          all_cmd_names = [[help commands | get name | str join "\n"]]
        }
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
