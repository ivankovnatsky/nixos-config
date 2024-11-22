{ pkgs, ... }:

{
  programs.nixvim = {
    extraPlugins = with pkgs; [
      (vimUtils.buildVimPlugin {
        pname = "nvim-jenkinsfile-linter";
        version = "b6b48b0a7aed92ed46bb9e1ab208dce92941f50b";
        src = pkgs.fetchFromGitHub {
          owner = "ckipp01";
          repo = "nvim-jenkinsfile-linter";
          rev = "b6b48b0a7aed92ed46bb9e1ab208dce92941f50b";
          hash = "sha256-NVEbTQtQTUwa932l1uALzrrEYUqYjfZ2n9IrP4vHqiw=";
        };
        meta = {
          homepage = "https://github.com/ckipp01/nvim-jenkinsfile-linter";
          description = "A Neovim plugin for linting Jenkinsfiles";
          license = pkgs.lib.licenses.mit;
        };
      })
      vimPlugins.plenary-nvim # Required dependency
    ];

    # Optional: Add configuration
    # extraConfigLua = ''
    #   require('jenkinsfile_linter').setup({ })
    # '';
  };
} 
