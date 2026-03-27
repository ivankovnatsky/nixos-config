{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    gnumake # To avoid installing Developer Tools
    tmux
    watchman # Be able to rerun rebuild manually with watching
    watchman-make # Be able to rerun rebuild manually with watching
    rebuild # Nix rebuild tool with simple and watch modes
    git

    rclone # Sync out stuff
    pigz # To help with Sources/ packing

    smctemp # Overlay
    dust # For disk usage analysis

    wget
    nixpkgs-darwin-master-ytdlp.yt-dlp
    gallery-dl

    asusrouter-cli
    mas

    # Required for Uptime Kuma tailscale-ping monitors
    tailscale
  ];
}
