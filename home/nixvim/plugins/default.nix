{
  programs.nixvim = {
    plugins = {
      neo-tree.enable = true;
      surround.enable = true;
      lualine.enable = true;
      lastplace.enable = true;
      commentary.enable = true;
      lsp-format.enable = true;
      fugitive.enable = true;
      gitblame.enable = true;
      # luasnip = {
      #   enable = true;
      #   extraConfig = {
      #     enable_autosnippets = true;
      #     store_selection_keys = "<Tab>";
      #   };
      # };
      lsp = {
        enable = true;
        servers = {
          nil_ls.enable = true;
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
    extraConfigLua = ''
      local _border = "rounded"

      vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
        vim.lsp.handlers.hover, {
          border = _border
        }
      )

      vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
        vim.lsp.handlers.signature_help, {
          border = _border
        }
      )

      vim.diagnostic.config{
        float={border=_border}
      };

      require('lspconfig.ui.windows').default_options = {
        border = _border
      }

      -- Fzf muscle memory
      vim.cmd [[command! Files Telescope find_files]]
      vim.cmd [[command! GFiles Telescope git_files]]
      vim.cmd [[command! GFiles Telescope git_files]]

      -- Command for static ripgrep search
      vim.cmd [[
      command! -nargs=? Rg lua require('telescope.builtin').grep_string({ search = <q-args> })
      ]]

      -- For dynamic searching, this command will prompt for input and update as you type
      vim.cmd [[
      command! -nargs=* RG call feedkeys(":Telescope live_grep<CR>")
      ]]

      -- Make the preview window wider
      require('telescope').setup({
        defaults = {
          layout_config = { width = 0.9 },
        },
      })
    '';
  };
}
