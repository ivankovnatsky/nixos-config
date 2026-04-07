{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    gnumake # To avoid installing Developer Tools
    tmux
    git

    nixpkgs-darwin-master-ytdlp.yt-dlp
    mas

    # Required for Uptime Kuma tailscale-ping monitors
    tailscale
  ];
}
