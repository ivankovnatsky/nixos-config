{ pkgs, ... }:
{
  programs.nixvim = {
    plugins = {
      octo.enable = true;
      lsp = {
        servers = {
          tinymist.enable = true;
          pyright.enable = true;
          gopls.enable = true;
          rust_analyzer = {
            enable = true;
            installCargo = true;
            installRustc = true;
          };
        };
      };
      none-ls = {
        sources = {
          formatting = {
            black = {
              enable = true;
              settings = ''
                {
                  extra_args = { "--fast" };
                }
              '';
            };
          };
        };
      };
      # copilot-vim.enable = true;
    };
    extraPlugins = with pkgs.vimPlugins; [
      vim-go
    ];
  };
}
