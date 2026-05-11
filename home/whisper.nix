{ config, pkgs, ... }:

let
  cacheDir = "${config.flags.externalStoragePath}/.cache";
  whisperBin = "${config.local.tools.toolsPrefix}/.local/bin/whisper";

  whisperWrapped = pkgs.writeShellScriptBin "whisper" ''
    exec ${whisperBin} \
      --model turbo \
      --model_dir ${cacheDir}/whisper \
      "$@"
  '';
in
{
  home.packages = [
    whisperWrapped
  ];
}
