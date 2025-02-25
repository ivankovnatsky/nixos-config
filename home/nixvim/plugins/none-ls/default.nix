{ pkgs, ... }:

{
  programs = {
    nixvim = {
      extraPackages = with pkgs; [ black ];
      plugins = {
        # null-ls fork
        none-ls = {
          enable = true;
          enableLspFormat = true;
          settings.update_in_insert = false;
          sources = {
            code_actions = {
              # gitsigns.enable = true;
            };
            # Normally I would wanted for native LSP to handle this, but for some
            # reason it stopped working, I'm not sure why, but I think I recall
            # that it worked before, at least for lua, nix and python files
            # only using LSP formatting capabilities.
            formatting = {
              fish_indent.enable = true;
              # nixfmt = "nixfmt-classic"; Uses wrong formatter, we need nixfmt-rfc-style.
              # nixfmt.enable = true;
              stylua.enable = true;
            };
          };
        };
      };
      keymaps = [{
        mode = [ "n" "v" ];
        key = "<leader>cf";
        action = "<cmd>lua vim.lsp.buf.format()<cr>";
        options = {
          silent = true;
          desc = "Format";
        };
      }];
    };
  };
}
