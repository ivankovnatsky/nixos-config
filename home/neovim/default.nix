{ pkgs, ... }:

{
  home.packages = with pkgs; [
    delta
    dhall-lsp-server
    gopls
    mdl
    nodejs
    nodePackages.bash-language-server
    nodePackages.pyright
    nodePackages.js-beautify
    python310Packages.grip
    ripgrep
    rnix-lsp
    shellcheck
    shfmt
    terraform-ls
    tflint
    rust-analyzer
  ];

  programs.neovim = {
    enable = true;

    plugins = with pkgs.vimPlugins; [
      {
        plugin = dhall-vim;
        config = ''
          autocmd FileType dhall setlocal ts=2 sts=2 sw=2 expandtab
        '';
      }
      {
        plugin = vim-jsonnet;
        config = ''
          autocmd FileType jsonnet setlocal ts=2 sts=2 sw=2 expandtab
        '';
      }
      {
        plugin = lualine-nvim;
        type = "lua";
        config = ''
          require'lualine'.setup {
            options = {
              component_separators = ''',
              section_separators = '''
            },
          }
        '';
      }
      {
        plugin = fidget-nvim;
        type = "lua";
        config = ''
          require("fidget").setup({})
        '';
      }
      lspkind-nvim
      vim-better-whitespace
      vim-strip-trailing-whitespace
      copilot-vim
      nvim-web-devicons
      {
        plugin = vim-commentary;
        config = '';
          autocmd FileType helm setlocal commentstring=#\ %s
        '';
      }
      {
        plugin = nvim-colorizer-lua;
        config = ''
          set termguicolors
          lua << END
          require 'colorizer'.setup()
          END
        '';
      }
      ansible-vim
      {
        plugin = dhall-vim;
        config = ''
          autocmd FileType dhall setlocal ts=2 sts=2 sw=2 expandtab
        '';
      }
      context-vim
      vim-fugitive
      vim-git
      vim-gitgutter
      {
        plugin = neoformat;
        config = ''
          augroup fmt
            autocmd!
            autocmd BufWritePre * undojoin | Neoformat
          augroup END
        '';
      }
      {
        plugin = vim-helm;
        config = ''
          autocmd FileType helm setlocal ts=2 sts=2 sw=2 expandtab
        '';
      }
      {
        plugin = rust-vim;
        config = ''
          let g:rustfmt_autosave = 1
        '';
      }
      vim-go
      vim-sleuth
      vim-lastplace
      vim-repeat
      vim-sensible
      git-blame-nvim
      {
        plugin = vim-sneak;
        config = ''
          let g:sneak#label = 1
        '';
      }
      mkdir-nvim
      vim-surround
      vim-tmux
      webapi-vim
      {
        plugin = fzf-vim;
        config = ''
          command! -bang -nargs=* Rg call fzf#vim#grep("rg --column --hidden --no-ignore-parent --glob '!.git/*' --line-number --no-heading --color=always --smart-case -- ".shellescape(<q-args>), 1, fzf#vim#with_preview(), <bang>0)
        '';
      }
      {
        plugin = cmp-buffer;
        type = "lua";
        config = ''
          require('cmp').setup({
            sources = {
              { name = 'buffer' },
            },
          })
        '';
      }
      {
        plugin = cmp-nvim-lsp;
        type = "lua";
        config = ''
          require'cmp'.setup {
            sources = {
              { name = 'nvim_lsp' }
            }
          }

          -- The nvim-cmp almost supports LSP's capabilities so You should advertise it to LSP servers..
          local capabilities = require('cmp_nvim_lsp').default_capabilities()

          -- The following example advertise capabilities to `clangd`.
          require'lspconfig'.clangd.setup {
            capabilities = capabilities,
          }
        '';
      }
      {
        plugin = cmp-path;
        type = "lua";
        config = ''
          require'cmp'.setup {
            sources = {
              { name = 'path' }
            }
          }
        '';
      }
      cmp-cmdline
      {
        plugin = nvim-cmp;
        type = "lua";
        config = ''
          -- Set up nvim-cmp.
          local cmp = require'cmp'

          cmp.setup({
            snippet = {
              -- REQUIRED - you must specify a snippet engine
              expand = function(args)
                vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
                -- require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
                -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
                -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
              end,
            },
            window = {
              -- completion = cmp.config.window.bordered(),
              -- documentation = cmp.config.window.bordered(),
            },
            mapping = cmp.mapping.preset.insert({
              ['<C-b>'] = cmp.mapping.scroll_docs(-4),
              ['<C-f>'] = cmp.mapping.scroll_docs(4),
              ['<C-Space>'] = cmp.mapping.complete(),
              ['<C-e>'] = cmp.mapping.abort(),
              ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
            }),
            sources = cmp.config.sources({
              { name = 'nvim_lsp' },
              { name = 'vsnip' }, -- For vsnip users.
              -- { name = 'luasnip' }, -- For luasnip users.
              -- { name = 'ultisnips' }, -- For ultisnips users.
              -- { name = 'snippy' }, -- For snippy users.
            }, {
              { name = 'buffer' },
            })
          })

          -- Set configuration for specific filetype.
          cmp.setup.filetype('gitcommit', {
            sources = cmp.config.sources({
              { name = 'cmp_git' }, -- You can specify the `cmp_git` source if you were installed it.
            }, {
              { name = 'buffer' },
            })
          })

          -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
          cmp.setup.cmdline({ '/', '?' }, {
            mapping = cmp.mapping.preset.cmdline(),
            sources = {
              { name = 'buffer' }
            }
          })

          -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
          cmp.setup.cmdline(':', {
            mapping = cmp.mapping.preset.cmdline(),
            sources = cmp.config.sources({
              { name = 'path' }
            }, {
              { name = 'cmdline' }
            })
          })

          -- Set up lspconfig.
          local capabilities = require('cmp_nvim_lsp').default_capabilities()
          -- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
          require('lspconfig')['bashls'].setup {
            capabilities = capabilities
          }

          require('lspconfig')['gopls'].setup {
            capabilities = capabilities
          }

          require('lspconfig')['rnix'].setup {
            capabilities = capabilities
          }

          require('lspconfig')['terraformls'].setup {
            capabilities = capabilities
          }

          require('lspconfig')['rust_analyzer'].setup {
            capabilities = capabilities
          }
        '';
      }
      {
        plugin = nvim-tree-lua;
        type = "lua";
        config = ''
          require'nvim-tree'.setup {
            respect_buf_cwd = true,
            disable_netrw = false,
            hijack_directories = {
              enable = true,
              auto_open = true,
            },
            actions = {
              use_system_clipboard = true,
              open_file = {
                resize_window = true,
              },
            },
            view = {
              side = 'left',
              width = 40,
              relativenumber = true,
            },
            git = {
              enable = true,
              ignore = false,
              timeout = 500,
            },
          }

          local function open_nvim_tree(data)

            -- buffer is a directory
            local directory = vim.fn.isdirectory(data.file) == 1

            if not directory then
              return
            end

            -- check if argument list is empty
            if vim.tbl_isempty(vim.fn.argv()) then
              -- create a new, empty buffer
              vim.cmd.enew()

              -- wipe the directory buffer
              vim.cmd.bw(data.buf)

              -- change to the directory
              vim.cmd.cd(data.file)

              -- open the tree
              require("nvim-tree.api").tree.open()
            end
          end

          open_nvim_tree({ buf = vim.fn.bufnr(), file = vim.fn.expand('%:p:h') })
        '';
      }
      {
        plugin = nvim-lspconfig;
        type = "lua";
        config = ''
          -- Disable logging
          vim.lsp.set_log_level("off")
          -- Mappings.
          -- See `:help vim.diagnostic.*` for documentation on any of the below functions
          local opts = { noremap=true, silent=true }
          vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, opts)
          vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
          vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
          vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, opts)

          -- Use an on_attach function to only map the following keys
          -- after the language server attaches to the current buffer
          local on_attach = function(client, bufnr)
            -- Enable completion triggered by <c-x><c-o>
            vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

            -- Mappings.
            -- See `:help vim.lsp.*` for documentation on any of the below functions
            local bufopts = { noremap=true, silent=true, buffer=bufnr }
            vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
            vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
            vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
            vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
            -- vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
            vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
            vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
            vim.keymap.set('n', '<space>wl', function()
              print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
            end, bufopts)
            vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
            vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
            vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
            vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
            vim.keymap.set('n', '<space>f', function() vim.lsp.buf.format { async = true } end, bufopts)
          end

          local lsp_flags = {
            -- This is the default in Nvim 0.7+
            debounce_text_changes = 150,
          }
          require('lspconfig')['pyright'].setup{
              on_attach = on_attach,
              flags = lsp_flags,
          }
          require('lspconfig')['bashls'].setup{
              on_attach = on_attach,
              flags = lsp_flags,
          }
          require('lspconfig')['dhall_lsp_server'].setup{
              on_attach = on_attach,
              flags = lsp_flags,
          }
          require('lspconfig')['gopls'].setup{
              on_attach = on_attach,
              flags = lsp_flags,
          }
          require('lspconfig')['rnix'].setup{
              on_attach = on_attach,
              flags = lsp_flags,
          }
          require('lspconfig')['terraformls'].setup{
              on_attach = on_attach,
              flags = lsp_flags,
          }
          require('lspconfig')['rust_analyzer'].setup{
              on_attach = on_attach,
              flags = lsp_flags,
          }

          require('lspkind').init({
            -- DEPRECATED (use mode instead): enables text annotations
            --
            -- default: true
            -- with_text = true,

            -- defines how annotations are shown
            -- default: symbol
            -- options: 'text', 'text_symbol', 'symbol_text', 'symbol'
            mode = 'symbol_text',

            -- default symbol map
            -- can be either 'default' (requires nerd-fonts font) or
            -- 'codicons' for codicon preset (requires vscode-codicons font)
            --
            -- default: 'default'
            preset = 'codicons',

            -- override preset symbols
            --
            -- default: {}
            symbol_map = {
              Text = "",
              Method = "",
              Function = "",
              Constructor = "",
              Field = "ﰠ",
              Variable = "",
              Class = "ﴯ",
              Interface = "",
              Module = "",
              Property = "ﰠ",
              Unit = "塞",
              Value = "",
              Enum = "",
              Keyword = "",
              Snippet = "",
              Color = "",
              File = "",
              Reference = "",
              Folder = "",
              EnumMember = "",
              Constant = "",
              Struct = "פּ",
              Event = "",
              Operator = "",
              TypeParameter = ""
            },
          })
        '';
      }

      {
        plugin = ale;
        config = ''
          let b:ale_linters = ['pylint', 'mdl']
        '';
      }

      {
        plugin = vim-markdown;
        config = ''
          let g:vim_markdown_folding_disabled = 1
        '';
      }
      vim-nix
      vim-terraform
      {
        plugin = vim-terraform-completion;
        config = ''
          set completeopt-=preview

          " (Optional)Hide Info(Preview) window after completions
          autocmd CursorMovedI * if pumvisible() == 0|pclose|endif
          autocmd InsertLeave * if pumvisible() == 0|pclose|endif

          " (Optional) Default: 0, enable(1)/disable(0) plugin's keymapping
          let g:terraform_completion_keys = 1

          " (Optional) Default: 1, enable(1)/disable(0) terraform module registry completion
          let g:terraform_registry_module_completion = 0
        '';
      }
    ];

    extraConfig = builtins.readFile ./init.vim;
  };
}
