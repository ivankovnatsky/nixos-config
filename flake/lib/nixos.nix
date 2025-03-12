{ inputs, ... }:
let
  inherit (import ./home.nix { inherit inputs; })
    nixosHomeManagerModule
    stableNixosHomeManagerModule
    ;
  inherit (import ./system.nix { inherit inputs; }) systemModule;

  # Helper function to create a NixOS system with a specific nixpkgs input
  makeNixosSystemWithPkgs =
    nixpkgsInput:
    {
      hostname,
      system,
      username,
      modules ? [ ],
      extraNixPath ? { },
    }:
    nixpkgsInput.lib.nixosSystem {
      inherit system;

      modules =
        (systemModule {
          inherit hostname extraNixPath;
          nixpkgsInput = nixpkgsInput;
          nixosReleaseInput = if nixpkgsInput == inputs.nixos-release then nixpkgsInput else null;
        })
        ++ modules;

      specialArgs = { inherit system username; };
    };

  # Helper function to create a NixOS system with home-manager and specific inputs
  makeNixosWithHomeAndPkgs =
    nixpkgsInput: homeManagerInput:
    {
      hostname,
      system,
      username,
      modules ? [ ],
      homeModules ? [ ],
      extraNixPath ? { },
    }:
    nixpkgsInput.lib.nixosSystem {
      inherit system;

      modules =
        (systemModule {
          inherit hostname extraNixPath;
          nixpkgsInput = nixpkgsInput;
          nixosReleaseInput = if nixpkgsInput == inputs.nixos-release then nixpkgsInput else null;
        })
        ++ (homeManagerInput {
          inherit hostname username system;
          extraImports = homeModules;
        })
        ++ modules;

      specialArgs = { inherit system username; };
    };
in
{
  # NixOS configuration with unstable channel (default)
  makeNixosConfig = makeNixosSystemWithPkgs inputs.nixpkgs;
  makeNixosWithHome = makeNixosWithHomeAndPkgs inputs.nixpkgs nixosHomeManagerModule;

  # NixOS configuration with stable release
  makeStableNixosConfig = makeNixosSystemWithPkgs inputs.nixos-release;

  # NixOS configuration with stable release and home-manager
  makeStableNixosWithHome = makeNixosWithHomeAndPkgs inputs.nixos-release stableNixosHomeManagerModule;
}
