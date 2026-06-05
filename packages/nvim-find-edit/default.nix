{ pkgs }:

pkgs.writeShellScriptBin "nvim-find-edit" ''
  export PATH="${
    pkgs.lib.makeBinPath [
      pkgs.ripgrep
      pkgs.neovim
    ]
  }:$PATH"
  exec ${pkgs.bash}/bin/bash ${./nvim-find-edit.sh} "$@"
''
