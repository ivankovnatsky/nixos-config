{
  programs.nixvim = {
    plugins = {
      neo-tree.enable = true;
      treesitter = {
        enable = true;
        indent = true;
        # folding = true;
      };
      treesitter-context.enable = true;
      surround.enable = true;
      lualine.enable = true;
      lastplace.enable = true;
      commentary.enable = true;
      lsp-format.enable = true;
      fugitive.enable = true;
      gitblame.enable = true;
      luasnip = {
        enable = true;
        extraConfig = {
          enable_autosnippets = true;
        };
      };
      lsp = {
        enable = true;
        servers = {
          nil_ls.enable = true;
          lua-ls.enable = true;
        };
        keymaps = {
          silent = true;
          lspBuf = {
            gd = {
              action = "definition";
              desc = "Goto Definition";
            };
            gr = {
              action = "references";
              desc = "Goto References";
            };
            gD = {
              action = "declaration";
              desc = "Goto Declaration";
            };
            gI = {
              action = "implementation";
              desc = "Goto Implementation";
            };
            gT = {
              action = "type_definition";
              desc = "Type Definition";
            };
            K = {
              action = "hover";
              desc = "Hover";
            };
            "<leader>cw" = {
              action = "workspace_symbol";
              desc = "Workspace Symbol";
            };
            "<leader>cr" = {
              action = "rename";
              desc = "Rename";
            };
          };
          diagnostic = {
            "<leader>cd" = {
              action = "open_float";
              desc = "Line Diagnostics";
            };
            "[d" = {
              action = "goto_next";
              desc = "Next Diagnostic";
            };
            "]d" = {
              action = "goto_prev";
              desc = "Previous Diagnostic";
            };
          };
        };
      };
      nvim-cmp = {
        enable = true;
        autoEnableSources = true;
        performance = {
          debounce = 60;
          fetchingTimeout = 200;
          maxViewEntries = 30;
        };
        snippet.expand = "luasnip";
        formatting.fields = [ "kind" "abbr" "menu" ];
        sources = [
          { name = "git"; }
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
    };
    extraConfigLua = builtins.readFile ./telescope.lua;
  };
}
