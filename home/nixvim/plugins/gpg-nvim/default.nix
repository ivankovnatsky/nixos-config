{ pkgs, ... }:

{
  # https://github.com/benoror/gpg.nvim
  programs.nixvim = {
    extraPlugins = with pkgs.vimUtils; [
      (buildVimPlugin rec {
        pname = "gpg.nvim";
        version = "26953b9c7486519c722f53ca372bba7bcb61a6bb";
        src = pkgs.fetchFromGitHub {
          owner = "benoror";
          repo = "gpg.nvim";
          rev = "${version}";
          hash = "sha256-ZpMvBt4YwSLLT+2FjRuhQ3ZZ7sK6XVsLurT+R+iaN1I=";
        };
      })
    ];
  };
}
