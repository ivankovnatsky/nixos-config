{ pkgs }:

let
  python = pkgs.python3.withPackages (ps: [ ps.click ]);
in
pkgs.writeShellScriptBin "giffer" ''
  export PATH="${
    pkgs.lib.makeBinPath [
      pkgs.curl
      pkgs.ffmpeg
      pkgs.gallery-dl
      pkgs.yt-dlp
    ]
  }:$PATH"
  exec ${python}/bin/python ${./giffer.py} "$@"
''
