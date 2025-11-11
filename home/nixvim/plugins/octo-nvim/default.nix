{ pkgs, ... }:

{
  # https://github.com/pwntester/octo.nvim
  # TODO: Add to nixpkgs?
  programs.nixvim = {
    extraPlugins = with pkgs.vimUtils; [
      (buildVimPlugin rec {
        pname = "octo.nvim";
        version = "11646cef0ad080a938cdbc181a4a3f7b59996c05";
        src = pkgs.fetchFromGitHub {
          owner = "pwntester";
          repo = "octo.nvim";
          rev = "${version}";
          hash = "sha256-bn/FOAJpFNccHWsLMgiLnyTcOz+TaIUsBq/xKOaAN8k=";
        };
        doCheck = false;
      })
    ];

    extraConfigLua = ''
      require('octo').setup({ })
    '';
  };
}
