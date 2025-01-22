{
  programs.nixvim.keymaps = [
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
    {
      mode = "n";
      key = "ZA";
      action = ":bd<CR>";
      options = {
        silent = true;
        desc = "Close buffer";
      };
    }
    {
      mode = "n";
      key = "ZX";
      action = ":w | bd<CR>";
      options = {
        silent = true;
        desc = "Save and close buffer";
      };
    }
    # TODO: Fix visual mode selection to use actual selected text instead of word under cursor
    # Possible approaches to investigate:
    # 1. Use vim.fn.getline("'<", "'>") with proper handling
    # 2. Create a helper function in Lua
    # 3. Use vim.fn.visualmode() and vim.fn.getpos()
    # 4. Look into how other plugins handle visual selections
    {
      mode = "n";
      key = "<leader>rg";
      action = ''
        function()
          require("telescope.builtin").live_grep({
            default_text = vim.fn.expand("<cword>")
          })
        end
      '';
      lua = true;
      options = {
        silent = true;
        desc = "Search word under cursor";
      };
    }
    {
      mode = "v";
      key = "<leader>rg";
      action = ''
        function()
          require("telescope.builtin").live_grep({
            default_text = vim.fn.expand("<cword>")
          })
        end
      '';
      lua = true;
      options = {
        silent = true;
        desc = "Search word under cursor";
      };
    }
    {
      mode = "n";
      key = "<leader>fi";
      action = ''
        function()
          require("telescope.builtin").find_files({
            default_text = vim.fn.expand("<cword>")
          })
        end
      '';
      lua = true;
      options = {
        silent = true;
        desc = "Find files with word under cursor";
      };
    }
    {
      mode = "v";
      key = "<leader>fi";
      action = ''
        function()
          require("telescope.builtin").find_files({
            default_text = vim.fn.expand("<cword>")
          })
        end
      '';
      lua = true;
      options = {
        silent = true;
        desc = "Find files with selected text";
      };
    }
  ];
}
