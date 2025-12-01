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
    ];
  };

  users.groups.nixbuilder = {};

  nix.settings = {
    # Allow nixbuilder user to act as a trusted user for remote builds
    trusted-users = [ "nixbuilder" username ];
  };
}
