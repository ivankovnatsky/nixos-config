{ pkgs, ... }:

{
  programs.nixvim = {
    extraPlugins = with pkgs; [
      (vimUtils.buildVimPlugin rec {
        pname = "vgit.nvim";
        version = "1.0.6";
        src = pkgs.fetchFromGitHub {
          owner = "tanvirtin";
          repo = "vgit.nvim";
          rev = "v1.0.6";
          hash = "sha256-2GkAs8f/jwKGsabhr1Ik90wh19QRBEwvsn5fVGTmBaQ=";
        };
        dontCheck = true;
        doCheck = false;
        doInstallCheck = false;
        meta = {
          homepage = "https://github.com/tanvirtin/vgit.nvim";
          description = "Visual git plugin for Neovim";
          license = pkgs.lib.licenses.mit;
        };
      })
      vimPlugins.plenary-nvim # Required dependency
      vimPlugins.nvim-web-devicons # Required dependency
    ];

    # Lazy loading on VimEnter event and setup
    extraConfigLua = ''
      -- VGit setup with lazy loading simulation
      vim.api.nvim_create_autocmd('VimEnter', {
        callback = function()
          require('vgit').setup({
            settings = {
              live_blame = {
                enabled = false,
              },
              scene = {
                diff_preference = 'unified', -- unified or split
              },
            }
          })
        end
      })
    '';
  };
}