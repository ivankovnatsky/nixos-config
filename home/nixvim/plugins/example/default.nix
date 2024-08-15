{ pkgs, ... }:
{
  programs.nixvim = {
    extraPlugins = with pkgs.vimUtils; [
      (buildVimPlugin rec {
        pname = "name.nvim";
        version = "1.0.0";
        src = pkgs.fetchFromGitHub {
          owner = "name";
          repo = "name.nvim";
          rev = "${version}";
          hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        };
      })
    ];

    extraConfigLua = ''
      require("name").setup({ })
    '';
  };
}
