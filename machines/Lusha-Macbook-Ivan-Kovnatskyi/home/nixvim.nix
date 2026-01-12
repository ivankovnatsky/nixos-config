{ pkgs, ... }:
{
  programs.nixvim = {
    # https://github.com/nix-community/nixvim/issues/1141#issuecomment-2054102360
    extraPackages = with pkgs; [ rustfmt ];
    editorconfig.enable = true;
    plugins = {
      # Using custom pinned version from home/nixvim/plugins/octo-nvim
      # Latest commit: https://github.com/pwntester/octo.nvim/commit/11646cef0ad080a938cdbc181a4a3f7b59996c05
      # octo.enable = true;
      notify.enable = true;
      kitty-scrollback = {
        enable = true;
        settings.kitty_get_text.ansi = false;
      };
      # TODO: Enable again after tmux all sessions and tmux itself is restarted.
      # image.enable = true;
      claude-code.enable = true;
      lint = {
        lintersByFt = {
          terraform = [ "tflint" ];
          text = [ "vale" ];
          json = [ "jsonlint" ];
          markdown = [ "vale" ];
          dockerfile = [ "hadolint" ];
          typescript = [ "eslint" ];
          javascript = [ "eslint" ];
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
          rust_analyzer = {
            enable = true;
            installCargo = true;
            installRustc = true;
          };
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
            # TODO: Tweak to disallow auto-formats for some specific files or
            # use separate tools for auto-fmt.
            # prettierd = {
            #   enable = true;
            #   settings = ''
            #     {
            #       extra_args = {};
            #     }
            #   '';
            # };
          };
        };
      };
      conform-nvim = {
        settings.formatters_by_ft = {
          python = [ "black" ];
          lua = [ "stylua" ];
          rust = [ "rustfmt" ];
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
}
