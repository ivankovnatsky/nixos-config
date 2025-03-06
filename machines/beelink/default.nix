{ pkgs, ... }:

{
  imports = [
    # Base configuration.
    ./configuration.nix

    ./syncthing.nix

    # Uncomment after enrolling TPM2 (see docs/beelink.md for instructions)
    ./cryptenroll.nix

    ./ssh.nix
    ./tmux-nixos-rebuild.nix
    # ./netdata.nix

    ./dns.nix
    ./http-routing.nix

    # Media
    # TODO: Consider using module? https://github.com/rasmus-kirk/nixarr
    ./plex.nix
    ./radarr.nix
    ./sonarr.nix
    ./transmission.nix
    ./prowlarr.nix

    ../../modules/secrets
  ];

  # Enable TPM2 support (required for TPM2 enrollment)
  security.tpm2.enable = true;

  # Additional system packages
  environment.systemPackages = with pkgs; [
    btop
    tmux
  ];
}
