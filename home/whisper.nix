{ config, pkgs, ... }:

let
  whisperWrapped = pkgs.writeShellScriptBin "whisper" ''
    exec ${pkgs.openai-whisper}/bin/whisper \
      --model turbo \
      --model_dir ${config.flags.externalStoragePath}/.whisper \
      "$@"
  '';
in
{
  home.packages = [
    whisperWrapped
  ];
}
