{ pkgs, ... }:

{
  # https://github.com/pwntester/octo.nvim
  # TODO: Add to nixpkgs?
  programs.nixvim = {
    extraPlugins = with pkgs.vimUtils; [
      (buildVimPlugin rec {
        pname = "octo.nvim";
        version = "b4923dc97555c64236c4535b2adf75c74c00caca";
        src = pkgs.fetchFromGitHub {
          owner = "pwntester";
          repo = "octo.nvim";
          rev = "${version}";
          hash = "sha256-dcWN16sHNhwpFKdEAo7409w87MMoLeq23hNGv3ilJ2A=";
        };
      })
    ];

    extraConfigLua = ''
      require('octo').setup({ })
    '';
  };
}
