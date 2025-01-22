{ pkgs, ... }:

{
  programs.nixvim = {
    # https://github.com/nix-community/nixvim/issues/1141#issuecomment-2054102360
    extraPackages = with pkgs; [ rustfmt ];
    plugins = {
      # TODO: Testing out
      # Autoformat tools make things harder apply fmt when it's not needed
      # auto-save.enable = true;
      neo-tree = {
        enable = true;
        filesystem = {
          filteredItems = {
            showHiddenCount = false;
            hideDotfiles = false;
            hideByName = [
              ".git"
            ];
          };
          # FIXME: I want to open files under URL, see if we can do it without netrw.
          # https://github.com/nix-community/nixvim/blob/f4b0b81ef9eb4e37e75f32caf1f02d5501594811/plugins/by-name/neo-tree/default.nix#L811
          hijackNetrwBehavior = "disabled";
        };
      };
      treesitter = {
        enable = true;
        settings.indent.enable = true;
        # folding = true;
      };
      treesitter-context.enable = true;
      vim-surround.enable = true;
      lualine.enable = true;
      lastplace.enable = true;
      commentary.enable = true;
      fugitive.enable = true;
      git-conflict.enable = true;
      auto-session = {
        enable = true;
      };
      mini = {
        enable = true;
      };
      # alpha = {
      #   enable = true;
      #   theme = "dashboard";
      # };
      # Somehow typing `r` in search escapes search and places cursor in text,
      # even though it did not find any occurrences
      # flash.enable = true;
      oil = {
        enable = true;
        settings = {
          # https://github.com/nix-community/nixvim/blob/f4b0b81ef9eb4e37e75f32caf1f02d5501594811/tests/test-sources/plugins/by-name/oil/default.nix#L40
          # https://github.com/stevearc/oil.nvim?tab=readme-ov-file#options
          # Don't disable netrw. I need it for URL file opening.
          default_file_explorer = false;
          view_options.show_hidden = true;
        };
      };
      undotree.enable = true;
      which-key.enable = true;
      # FIXME: Will comment for now. Had hardtime with hardtime plugin.
      # hardtime = {
      #   enable = true;
      #   settings = {
      #     enabled = true;
      #     disable_mouse = true;
      #     disabled_filetypes = [ "Oil" ];
      #     hint = true;
      #     max_count = 4;
      #     max_time = 1000;
      #     restriction_mode = "hint";
      #     restricted_keys = { };
      #   };
      # };
      nvim-autopairs.enable = true;
      illuminate = {
        enable = true;
        underCursor = false;
        filetypesDenylist = [
          "Outline"
          "TelescopePrompt"
          "alpha"
          "harpoon"
          "reason"
        ];
      };
      conform-nvim = {
        enable = true;
        settings = {
          format_on_save = {
            lsp_fallback = true;
            timeout_ms = 500;
          };
          notify_on_error = true;
          formatters_by_ft = {
            rust = [ "rustfmt" ];
          };
        };
      };
      luasnip = {
        enable = true;
        settings = {
          enable_autosnippets = true;
          store_selection_keys = "<Tab>";
        };
        fromVscode = [
          {
            lazyLoad = true;
            paths = "${pkgs.vimPlugins.friendly-snippets}";
          }
        ];
      };
      trouble.enable = true;
      cmp-emoji.enable = true;
      cmp-spell.enable = true;
      cmp = {
        enable = true;
        settings = {
          autoEnableSources = true;
          performance = {
            debounce = 60;
            fetchingTimeout = 200;
            maxViewEntries = 30;
          };
          snippet = {
            expand = ''
              function(args)
                require('luasnip').lsp_expand(args.body)
              end
            '';
          };
          formatting.fields = [ "kind" "abbr" "menu" ];
          sources = [
            { name = "git"; }
            { name = "emoji"; }
            { name = "spell"; }
            { name = "nvim_lsp"; }
            {
              name = "buffer"; # text within current buffer
              option.get_bufnrs.__raw = "vim.api.nvim_list_bufs";
              keywordLength = 3;
            }
            {
              name = "path"; # file system paths
              keywordLength = 3;
            }
            {
              name = "luasnip"; # snippets
              keywordLength = 3;
            }
          ];
          mapping = {
            "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
            "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
            "<C-j>" = "cmp.mapping.select_next_item()";
            "<C-k>" = "cmp.mapping.select_prev_item()";
            "<C-e>" = "cmp.mapping.abort()";
            "<C-b>" = "cmp.mapping.scroll_docs(-4)";
            "<C-f>" = "cmp.mapping.scroll_docs(4)";
            "<C-Space>" = "cmp.mapping.complete()";
            "<CR>" = "cmp.mapping.confirm({ select = true })";
            "<S-CR>" = "cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true })";
          };
        };
      };
      cmp-nvim-lsp.enable = true; # lsp
      cmp-buffer.enable = true;
      cmp-path.enable = true; # file system paths
      cmp_luasnip.enable = true; # snippets
      cmp-cmdline.enable = false; # autocomplete for cmdline
      telescope = {
        enable = true;
        extensions = {
          # file-browser = {
          #   enable = true;
          # };
          fzf-native = {
            enable = true;
          };
        };
        # settings = {
        #   defaults = {
        #     layout_config = {
        #       horizontal = {
        #         prompt_position = "top";
        #       };
        #     };
        #     sorting_strategy = "ascending";
        #   };
        # };
      };
      web-devicons.enable = true;
    };
    extraConfigLua =
      builtins.readFile ./telescope.lua;
  };
}
