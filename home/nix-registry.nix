{ ... }:

let
  # Pin nixpkgs to a specific commit to avoid slow registry lookups.
  # Update this periodically with the latest nixpkgs master commit.
  nixpkgsRev = "03cac5a32a37b74cd341c90ac2f08acb4228c88c";

  registryJson = builtins.toJSON {
    version = 2;
    flakes = [
      {
        from = {
          type = "indirect";
          id = "nixpkgs";
        };
        to = {
          type = "github";
          owner = "NixOS";
          repo = "nixpkgs";
          rev = nixpkgsRev;
        };
        exact = true;
      }
    ];
  };
in
{
  xdg.configFile."nix/registry.json".text = registryJson;
}
