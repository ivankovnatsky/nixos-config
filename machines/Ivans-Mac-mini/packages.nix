{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    gnumake # To avoid installing Developer Tools
    rclone # Sync out stuff
    tmux # Be able to attach to tmux-rebuild session manually
    watchman # Be able to rerun rebuild manually with watching
    watchman-make # Be able to rerun rebuild manually with watching
  ];
}
