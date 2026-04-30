{ pkgs }:

let
  src = ./.;
  python = pkgs.python3.withPackages (ps: [ ps.click ]);
in
pkgs.writeShellScriptBin "giffer" ''
  export PATH="${
    pkgs.lib.makeBinPath [
      pkgs.curl
      pkgs.ffmpeg
      pkgs.nixpkgs-darwin-master-gallery-dl.gallery-dl
      pkgs.nixpkgs-darwin-master-ytdlp.yt-dlp
    ]
  }:$PATH"
  export PYTHONPATH="${src}"
  exec ${python}/bin/python ${src}/giffer.py "$@"
''
