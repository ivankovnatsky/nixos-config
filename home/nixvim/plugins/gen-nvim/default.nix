{ pkgs, ... }:

{
  # https://github.com/David-Kunz/gen.nvim
  # TODO: Add to nixpkgs?
  programs.nixvim = {
    extraPlugins = with pkgs.vimUtils; [
      (buildVimPlugin rec {
        pname = "gen.nvim";
        version = "c9a73d8c0d462333da6d2191806ff98f2884d706";
        src = pkgs.fetchFromGitHub {
          owner = "David-Kunz";
          repo = "gen.nvim";
          rev = "${version}";
          hash = "sha256-Yp7HrDMOyR929AfM7IjEz4dP3RhIx9kXZ1Z3zRr5yJg=";
        };
      })
    ];

    extraConfigLua = ''
      require('gen').setup({
        -- same as above
      })
    '';
  };
}
