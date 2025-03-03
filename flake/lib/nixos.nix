{ inputs, ... }:
let
  inherit (import ./home.nix { inherit inputs; }) homeManagerModule;
  inherit (import ./system.nix { inherit inputs; }) systemModule;
in
{
  # Base NixOS system configuration without home-manager
  makeBaseNixosSystem =
    {
      hostname,
      system,
      username,
      modules ? [],
    }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;

      modules =
        (systemModule { inherit hostname; })
        ++ modules;

      specialArgs = { inherit system username; };
    };

  # NixOS configuration with home-manager
  makeNixosWithHome =
    {
      hostname,
      system,
      username,
      modules ? [],
      homeModules ? [],
    }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;

      modules =
        (systemModule { inherit hostname; })
        ++ (homeManagerModule {
          inherit hostname username system;
          extraImports = homeModules;
        })
        ++ modules;

      specialArgs = { inherit system username; };
    };
}
