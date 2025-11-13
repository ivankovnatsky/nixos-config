{ username, pkgs, ... }:
{
  # Create a dedicated user for remote builds
  users.users.nixbuilder = {
    isSystemUser = true;
    group = "nixbuilder";
    description = "Nix remote build user";
    home = "/var/lib/nixbuilder";
    createHome = true;
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINduoENZ5s/uUim5k74kdZRDavAcIdtoY/txnn+ueXOQ root@steamdeck"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBAVbd/fRD0/cnBznyI7AtsCXVeM1Mr2hzQXY7nufT4S ivan@steamdeck"
    ];
  };

  users.groups.nixbuilder = { };

  nix.settings = {
    # Allow nixbuilder user to act as a trusted user for remote builds
    trusted-users = [ "nixbuilder" username ];
  };
}
