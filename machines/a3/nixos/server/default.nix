{
  imports = [
    ./configuration.nix
    ./networking.nix
    ./nixpkgs.nix
    ./security.nix
    ./storage-disk.nix

    ./dns.nix
    ./nextdns.nix

    ./power-monitoring.nix

    ./beszel.nix
    ./forgejo
    ./http.nix
    ./ollama.nix
    ./open-webui.nix
    ./remote-build.nix
    ./reposync.nix
    # ./smb.nix
    ./stash.nix
    ./syncthing-mgmt.nix
    ./uptime-kuma.nix
  ];
}
