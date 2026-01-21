{ pkgs }:

pkgs.writeShellScriptBin "find-grep" ''
  export PATH="${
    pkgs.lib.makeBinPath [
      pkgs.ripgrep
      pkgs.fzf
      pkgs.bat
      pkgs.neovim
    ]
  }:$PATH"
  exec ${pkgs.bash}/bin/bash ${./find-grep.sh} "$@"
''
