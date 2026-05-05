{ config, pkgs, ... }:

let
  cacheDir = "${config.flags.externalStoragePath}/.cache";

  whisperWrapped = pkgs.writeShellScriptBin "whisper" ''
    exec ${pkgs.openai-whisper}/bin/whisper \
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
