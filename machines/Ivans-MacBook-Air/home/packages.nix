{ pkgs, ... }:
{
  home.packages = with pkgs; [
    (python313.withPackages (
      ps: with ps; [
        grip
        # markitdown — pulls python3-speechrecognition → openai-whisper, whose
        # check phase fails on aarch64-darwin ("Failed to load audio" via
        # ffmpeg in the sandbox). Re-enable once upstream nixpkgs lands a fix.
        # markitdown
      ]
    ))
    typos
  ];
}
