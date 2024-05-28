{ pkgs, ... }:

{
  programs = {
    nixvim = {
      extraPackages = with pkgs; [ black ];
      plugins = {
        none-ls = {
          enable = true;
          enableLspFormat = true;
          updateInInsert = false;
          sources = {
            code_actions = {
              gitsigns.enable = true;
            };
            # Normally I would wanted for native LSP to handle this, but for some
            # reason it stopped working, I'm not sure why, but I think I recall
            # that it worked before, at least for lua, nix and python files
            # only using LSP formatting capabilities.
            formatting = {
              nixpkgs_fmt.enable = true;
              stylua.enable = true;
              black = {
                enable = true;
                withArgs = ''
                  {
                    extra_args = { "--fast" },
                  }
                '';
              };
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
