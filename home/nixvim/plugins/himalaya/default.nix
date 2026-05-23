{ pkgs, ... }:

{
  programs.nixvim = {
    extraPlugins = with pkgs.vimUtils; [
      pkgs.vimPlugins.himalaya-vim
      (buildVimPlugin rec {
        pname = "vim-himalaya-ui";
        version = "7f84b8174aa781af7bc3c4b9c7e4bb39e20475e2";
        src = pkgs.fetchFromGitHub {
          owner = "aliyss";
          repo = "vim-himalaya-ui";
          rev = version;
          hash = "sha256-usXHM6ISGoLPSQsT0lBaYX9y1bJXjPoRhNath/lKkGg=";
        };
      })
      (buildVimPlugin rec {
        pname = "himalaya.nvim";
        version = "d56a177e6ed6152da02d051e39d67ecdcf0de6ce";
        src = pkgs.fetchFromGitHub {
          owner = "knownasnaffy";
          repo = "himalaya.nvim";
          rev = version;
          hash = "sha256-kamZKE/VpMPenc67JtjS/jsmNrYx7VgxJAuBbvKJ1aM=";
        };
      })
    ];
  };
}
