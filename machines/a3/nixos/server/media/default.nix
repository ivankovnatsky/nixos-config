{
  imports = [
    ./lidarr.nix
    ./prowlarr.nix
    ./radarr.nix
    ./sonarr.nix
    ./transmission.nix
  ];

  # Shared group for cross-service handoff between transmission and the *arr
  # services in this directory (UMask=0002 + setgid dirs make new files
  # group-writable so radarr/sonarr/lidarr can import out of transmission's
  # download dir).
  users.groups.media = { };
}
