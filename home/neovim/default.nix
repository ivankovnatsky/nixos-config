{ pkgs, ... }:

{
  home.packages = with pkgs; [
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
        config = ''
          lua << EOF
          require'nvim-tree'.setup {
            respect_buf_cwd = true,
            disable_netrw       = false,
            hijack_directories   = {
              enable = true,
              auto_open = true,
            },
            actions = {
              open_file = {
                resize_window = true,
              },
            },
            renderer = {
              icons = {
                glyphs = {
                  default = '',
                },
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
          EOF
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
          local servers = { 'bashls', 'dhall_lsp_server', 'pyright', 'rnix', 'terraformls' }
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
