{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    gnumake # To avoid installing Developer Tools
    tmux
    git

    mas

    # Required for Uptime Kuma tailscale-ping monitors
    tailscale
  ];
}
