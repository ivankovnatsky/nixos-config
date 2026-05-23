{ pkgs, ... }:

{
  programs.nixvim = {
    extraPlugins = [
      pkgs.vimPlugins.nui-nvim
      (pkgs.vimUtils.buildVimPlugin rec {
        pname = "himalaya.nvim";
        version = "d56a177e6ed6152da02d051e39d67ecdcf0de6ce";
        src = pkgs.fetchFromGitHub {
          owner = "knownasnaffy";
          repo = "himalaya.nvim";
          rev = version;
          hash = "sha256-kamZKE/VpMPenc67JtjS/jsmNrYx7VgxJAuBbvKJ1aM=";
        };
        dependencies = [ pkgs.vimPlugins.nui-nvim ];
      })
    ];
  };
}
