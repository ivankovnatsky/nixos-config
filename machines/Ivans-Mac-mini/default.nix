{
  imports = [
    ../../darwin/syncthing.nix
    ../../modules/darwin/logrotate
    ../../modules/flags
    ../../modules/secrets
    ./dns.nix
    ./doh.nix
    ./git.nix
    ./logrotate.nix
    ./miniserve.nix
    ./netdata.nix
    ./nix.nix
    ./openssh.nix
    ./packages.nix
    ./http.nix
    ./sharing.nix
    ./sudo.nix
    ./power.nix
    # ./user.nix
    ./tmux-rebuild.nix
    ./system.nix
  ];
}
