{ pkgs, ... }:

{
  home.packages = with pkgs; [
    gopls
    dhall-lsp-server
    rnix-lsp
    nodePackages.pyright
    nodePackages.bash-language-server
    terraform-ls

    mdl
    black
    shellcheck

    python38Packages.grip

    ripgrep
  ];

  programs.neovim = {
    enable = true;

    plugins = with pkgs.vimPlugins; [
      {
        plugin = dhall-vim;
        config = ''
          autocmd FileType dhall setlocal ts=2 sts=2 sw=2 expandtab
          let g:dhall_format=1
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
        plugin = registers-nvim;
        config = ''
          let g:registers_normal_mode = 0
          let g:registers_visual_mode = 0
          let g:registers_insert_mode = 0
          let g:registers_window_border = "rounded"
        '';
      }
      {
        plugin = dhall-vim;
        config = ''
          autocmd FileType dhall setlocal ts=2 sts=2 sw=2 expandtab
        '';
      }
      vim-fugitive
      vim-git
      vim-gitgutter
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
      vim-visualstar
      webapi-vim
      {
        plugin = fzf-vim;
        config = ''
          command! -bang -nargs=* Rg call fzf#vim#grep("rg --column --hidden --no-ignore-parent --glob '!.git/*' --line-number --no-heading --color=always --smart-case -- ".shellescape(<q-args>), 1, fzf#vim#with_preview(), <bang>0)
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
              open_file = {
                resize_window = true,
              },
            },
            open_on_setup = true,
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
        '';
      }
      {
        plugin = nvim-lspconfig;
        type = "lua";
        config = ''
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
            vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
            vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
            vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
            vim.keymap.set('n', '<space>wl', function()
              print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
            end, bufopts)
            vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
            vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
            vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
            vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
            vim.keymap.set('n', '<space>f', vim.lsp.buf.formatting, bufopts)
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

      {
        plugin = vim-nix;
        config = ''
          autocmd BufWritePost *.nix silent !nixpkgs-fmt <afile>
          autocmd BufWritePost *.nix silent edit
        '';
      }

      {
        plugin = vim-terraform;
        config = ''
          let g:terraform_fmt_on_save=1
        '';
      }

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
