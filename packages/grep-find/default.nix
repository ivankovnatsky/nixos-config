{ pkgs }:

pkgs.writeShellScriptBin "grep-find" ''
  export PATH="${
    pkgs.lib.makeBinPath [
      pkgs.ripgrep
      pkgs.fzf
      pkgs.bat
      pkgs.neovim
    ]
  }:$PATH"
  exec ${pkgs.bash}/bin/bash ${./grep-find.sh} "$@"
''
