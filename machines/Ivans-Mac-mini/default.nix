{
  imports = [
    ../../darwin/syncthing.nix
    ../../modules/darwin/logrotate
    ../../modules/flags
    ../../modules/secrets
    ./dns.nix
    ./logrotate.nix
    ./netdata.nix
    ./nix.nix
    ./openssh.nix
    ./packages.nix
    ./sharing.nix
    ./sudo.nix
    ./tmux-rebuild.nix
  ];
}
