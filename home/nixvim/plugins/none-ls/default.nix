{
  programs = {
    nixvim = {
      plugins = {
        none-ls = {
          enable = true;
          enableLspFormat = true;
          updateInInsert = false;
          sources = {
            code_actions = {
              gitsigns.enable = true;
            };
            formatting = {
              nixpkgs_fmt.enable = true;
              stylua.enable = true;
            };
          };
        };
      };
      keymaps = [
        {
          mode = [ "n" "v" ];
          key = "<leader>cf";
          action = "<cmd>lua vim.lsp.buf.format()<cr>";
          options = {
            silent = true;
            desc = "Format";
          };
        }
      ];
    };
  };
}
