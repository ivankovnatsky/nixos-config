{ pkgs, ... }:
{
  programs.nixvim = {
    # https://github.com/nix-community/nixvim/issues/1141#issuecomment-2054102360
    extraPackages = with pkgs; [ rustfmt ];
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
      conform-nvim = {
        formatters_by_ft = {
          rust = [ "rustfmt" ];
        };
      };
      # copilot-vim.enable = true;
    };
    extraPlugins = with pkgs.vimPlugins; [
      vim-go
    ];
  };
}
