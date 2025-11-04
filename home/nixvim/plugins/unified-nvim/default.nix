{ pkgs, ... }:

{
  # https://github.com/axkirillov/unified.nvim
  programs.nixvim = {
    extraPlugins = with pkgs.vimUtils; [
      (buildVimPlugin rec {
        pname = "unified.nvim";
        version = "5831251be3a4d552f15a32565fe1a3f07c6a4a94";
        src = pkgs.fetchFromGitHub {
          owner = "axkirillov";
          repo = "unified.nvim";
          rev = "${version}";
          hash = "sha256-xE+IuPc9om/gAT39jTE4pw4xV1XDrdR/3UNLFqkp4ss=";
        };
      })
    ];

    extraConfigLua = ''
      require('unified').setup({ })
    '';
  };
}
