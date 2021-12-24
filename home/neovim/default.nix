{ pkgs, ... }:

{
  home.packages = with pkgs; [
    rnix-lsp
    nodePackages.pyright
    nodePackages.bash-language-server
    terraform-ls

    mdl
    black
    shellcheck

    python38Packages.pip
    python38Packages.grip
    python38Packages.pylint
  ];

  programs.neovim = {
    enable = true;

    plugins = with pkgs.vimPlugins; [
      {
        plugin = lualine-nvim;
        config = ''
          lua << END
          require'lualine'.setup {
            options = {
              component_separators = ''',
              section_separators = '''
            },
          }
          END
        '';
      }
      nvim-web-devicons
      {
        plugin = vim-commentary;
        config = '';
          autocmd FileType helm setlocal commentstring=#\ %s
        '';
      }
      ansible-vim
      vim-fugitive
      vim-git
      vim-gitgutter
      {
        plugin = vim-helm;
        config = ''
          autocmd FileType helm setlocal ts=2 sts=2 sw=2 expandtab
        '';
      }
      vim-sleuth
      vim-lastplace
      vim-repeat
      vim-sensible
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
        config = ''
          let g:nvim_tree_respect_buf_cwd = 1
          let g:nvim_tree_icons = {
            \ 'default': '',
            \ }

          lua << EOF
          require'nvim-tree'.setup {
            disable_netrw       = false,
            update_to_buf_dir   = {
              enable = true,
              auto_open = true,
            },
            open_on_setup = true,
            view = {
              side = 'left',
              width = 50,
              auto_resize = true,
            },
            git = {
              enable = true,
              ignore = false,
              timeout = 500,
            },
          }

          require'nvim-tree.view'.View.winopts.relativenumber = true
          EOF
        '';
      }
      {
        plugin = vim-jsonnet;
        config = ''
          autocmd FileType jsonnet setlocal ts=2 sts=2 sw=2 expandtab
        '';
      }
      {
        plugin = nvim-lspconfig;
        config = ''
          lua << EOF
          local nvim_lsp = require('lspconfig')

          -- Use an on_attach function to only map the following keys
          -- after the language server attaches to the current buffer
          local on_attach = function(client, bufnr)
            local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
            local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

            -- Enable completion triggered by <c-x><c-o>
            buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

            -- Mappings.
            local opts = { noremap=true, silent=true }

            -- See `:help vim.lsp.*` for documentation on any of the below functions
            buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
            buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
            buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
            buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
            -- buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
            buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
            buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
            buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
            buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
            buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
            buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
            buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
            buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
            buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
            buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
            buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
            buf_set_keymap('n', '<space>f', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)

          end

          -- Use a loop to conveniently call 'setup' on multiple servers and
          -- map buffer local keybindings when the language server attaches
          local servers = { 'bashls', 'pyright', 'rnix', 'terraformls' }
          for _, lsp in ipairs(servers) do
            nvim_lsp[lsp].setup {
              on_attach = on_attach,
              flags = {
                debounce_text_changes = 150,
              }
            }
          end
          EOF
        '';
      }

      {
        plugin = ale;
        config = ''
          let b:ale_linters = ['pylint', 'mdl']
        '';
      }

      {
        plugin = lens-vim;
        config = ''
          let g:lens#disabled_filetypes = ['NvimTree', 'fzf']
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
