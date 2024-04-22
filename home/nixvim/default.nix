{ config, pkgs, ... }:

let
  nvim-spell-uk-utf8-dictionary = builtins.fetchurl {
    url = "http://ftp.vim.org/vim/runtime/spell/uk.utf-8.spl";
    sha256 = "05180znfdjwqhl2gfsq42jzwqadd7cgr59p9cvz6hw2dlnj6qs71";
  };
in
{
  home.file."${config.xdg.configHome}/nvim/spell/uk.utf-8.spl".source = nvim-spell-uk-utf8-dictionary;
  imports = [
    ./config
  ];
  programs.nixvim = {
    enable = true;
    globals.mapleader = "<Space>";
    options = {
      # My options
      # Background
      background = if config.variables.darkMode then "dark" else "light";

      # Disable mouse mode
      mouse = "";

      foldmethod = "marker";
      autowrite = true;
      lazyredraw = true;
      showmatch = true;
      # Display commands typing in
      showcmd = true;

      # My options end

      # Enable relative line numbers
      number = true;
      relativenumber = true;

      # Set tabs to 2 spaces
      tabstop = 2;
      softtabstop = 2;

      # Always show tabs
      showtabline = 2;
      expandtab = true;

      # Enable auto indenting and set it to spaces
      smartindent = true;
      shiftwidth = 2;

      # Enable smart indenting (see https://stackoverflow.com/questions/1204149/smart-wrap-in-vim)
      breakindent = true;

      # Enable incremental searching
      hlsearch = true;
      incsearch = true;

      # Enable text wrap
      wrap = true;

      # Better splitting
      splitbelow = true;
      splitright = true;

      # Enable ignorecase + smartcase for better searching
      ignorecase = true;
      smartcase = true; # Don't ignore case with capitals
      grepprg = "rg --vimgrep";
      grepformat = "%f:%l:%c:%m";

      # Decrease updatetime
      updatetime = 50; # faster completion (4000ms default)

      # Set completeopt to have a better completion experience
      completeopt = [ "menuone" "noselect" "noinsert" ]; # mostly just for cmp

      # Enable persistent undo history
      swapfile = false;
      backup = false;
      undofile = true;

      # Enable 24-bit colors
      termguicolors = true;

      # Enable the sign column to prevent the screen from jumping
      # signcolumn = "yes";

      # Enable cursor line highlight
      cursorline = true; # Highlight the line where the cursor is located

      # Set fold settings
      # These options were reccommended by nvim-ufo
      # See: https://github.com/kevinhwang91/nvim-ufo#minimal-configuration
      foldcolumn = "0";
      foldlevel = 99;
      foldlevelstart = 99;
      foldenable = true;

      # Always keep 8 lines above/below cursor unless at start/end of file
      scrolloff = 8;

      # Place a column line
      # colorcolumn = "80";

      # Reduce which-key timeout to 10ms
      timeoutlen = 10;

      # Set encoding type
      encoding = "utf-8";
      fileencoding = "utf-8";

      # More space in the neovim command line for displaying messages
      cmdheight = 0;

      # We don't need to see things like INSERT anymore
      showmode = false;
    };
    keymaps = [
      {
        mode = "n";
        key = "<C-h>";
        action = "<C-W>h";
        options = {
          silent = true;
          desc = "Move to window left";
        };
      }
      {
        mode = "n";
        key = "<C-l>";
        action = "<C-W>l";
        options = {
          silent = true;
          desc = "Move to window right";
        };
      }
      {
        mode = "n";
        key = "<C-k>";
        action = "<C-W>k";
        options = {
          silent = true;
          desc = "Move to window over";
        };
      }
      {
        mode = "n";
        key = "<C-j>";
        action = "<C-W>j";
        options = {
          silent = true;
          desc = "Move to window bellow";
        };
      }
    ];
    extraPlugins = with pkgs.vimPlugins; [
      vim-nix
      vim-strip-trailing-whitespace
      vim-sensible
      vim-sleuth
      neoformat
    ];
    plugins = {
      neo-tree.enable = true;
      surround.enable = true;
      lualine.enable = true;
      lastplace.enable = true;
      commentary.enable = true;
      lsp-format.enable = true;
      fugitive.enable = true;
      lsp = {
        enable = true;
        servers = {
          nil_ls = {
            enable = true;
          };
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
    '';
  };
}
