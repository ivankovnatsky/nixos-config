{ config, pkgs, ... }:

let
  cacheDir = "${config.flags.externalStoragePath}/.cache";

  whisperWrapped = pkgs.writeShellScriptBin "whisper" ''
    exec ${pkgs.openai-whisper}/bin/whisper \
      --model turbo \
      --model_dir ${cacheDir}/whisper \
      "$@"
  '';

  mlxWhisperWrapped = pkgs.writeShellScriptBin "mlx_whisper" ''
    export HF_HOME="${cacheDir}/huggingface"
    exec ${pkgs.mlx-whisper}/bin/mlx_whisper \
      --model mlx-community/whisper-turbo \
      "$@"
  '';
in
{
  home.packages = [
    whisperWrapped
    mlxWhisperWrapped
  ];

}
