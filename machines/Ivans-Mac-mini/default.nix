{
  imports = [
    # ./user.nix
    ../../darwin/syncthing.nix
    ../../modules/darwin/logrotate
    ../../modules/flags
    ../../modules/secrets
    ./dns.nix
    ./doh.nix
    ./git.nix
    ./homebrew.nix
    ./http.nix
    ./logrotate.nix
    ./miniserve.nix
    ./netdata.nix
    ./nix.nix
    ./openssh.nix
    ./packages.nix
    ./power.nix
    ./sharing.nix
    ./sudo.nix
    ./system.nix
    ./tmux-rebuild.nix
  ];
}
