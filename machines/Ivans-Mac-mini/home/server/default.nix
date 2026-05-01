{
  imports = [
    ./beszel.nix
    ./bin.nix
    ./download-youtube
    ./forgejo
    ./healthchecks
    ./jellyfin
    # ./logscanner.nix
    ./media
    ./miniserve.nix
    ./monitoring
    ./navidrome
    ./ollama.nix
    ./open-webui.nix
    ./podservice
    ./reposync.nix
    ./restart-unhealthy.nix
    ./stash
    ./stash-media
    ./syncthing-mgmt.nix
    ./textcast
    ./uptime-kuma
  ];
}
