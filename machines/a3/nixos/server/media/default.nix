{
  imports = [
    ./jellyfin.nix
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

  # Claim the shared media root so descendants don't trip systemd-tmpfiles'
  # "unsafe path transition" check. Without this, /storage/data/media stays
  # owned by `ivan` and tmpfiles refuses to canonicalize through it when
  # creating children owned by service users (transmission, sonarr, ...).
  # Symptom: grandchild dirs like downloads/.incomplete, downloads/watchdir,
  # downloads/tv-sonarr never get created → transmission fails with
  # status=226/NAMESPACE on the BindPaths step.
  systemd.tmpfiles.rules = [
    "d /storage/data/media 2775 root media -"
  ];
}
