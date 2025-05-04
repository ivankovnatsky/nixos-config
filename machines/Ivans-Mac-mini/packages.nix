{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    gnumake # To avoid installing Developer Tools
    tmux # Be able to attach to tmux-rebuild session manually
    watchman # Be able to rerun rebuild manually with watching
    watchman-make # Be able to rerun rebuild manually with watching

    rclone # Sync out stuff
    pigz # To help with Sources/ packing

    smctemp # Overlay
    stats # macOS: System stats; Configure `Check for update` to `Never`.
    dust # For disk usage analysis

    wget
    yt-dlp
  ];
}
