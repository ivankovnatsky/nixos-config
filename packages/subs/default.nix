{ pkgs }:

# `subs` drives the actual Whisper engines (openai-whisper CUDA on a3,
# mlx-whisper on mini) via uv/the a3 wrapper — this derivation only provides the
# Click front-end and ensures ffmpeg is on PATH for audio extraction.
pkgs.writeShellScriptBin "subs" ''
  export PATH="${pkgs.ffmpeg}/bin:$PATH"
  exec ${pkgs.python3.withPackages (ps: [ ps.click ])}/bin/python ${./subs.py} "$@"
''
