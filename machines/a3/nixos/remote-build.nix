{ username, ... }:
{
  nix.settings = {
    # Allow the user to use this machine as a remote builder
    trusted-users = [ username ];
  };
}
