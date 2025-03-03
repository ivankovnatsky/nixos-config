{ inputs, ... }:
let
  inherit (import ./home.nix { inherit inputs; }) homeManagerModule;
  inherit (import ./system.nix { inherit inputs; }) systemModule;
  
  # Helper function to create a NixOS system with a specific nixpkgs input
  makeNixosSystemWithPkgs = nixpkgsInput: 
    {  
      hostname,
      system,
      username,
      modules ? [],
      extraNixPath ? {},
    }:
    nixpkgsInput.lib.nixosSystem {
      inherit system;

      modules =
        (systemModule { inherit hostname extraNixPath; })
        ++ modules;

      specialArgs = { inherit system username; };
    };
    
  # Helper function to create a NixOS system with home-manager and a specific nixpkgs input
  makeNixosWithHomeAndPkgs = nixpkgsInput:
    {
      hostname,
      system,
      username,
      modules ? [],
      homeModules ? [],
      extraNixPath ? {},
    }:
    nixpkgsInput.lib.nixosSystem {
      inherit system;

      modules =
        (systemModule { inherit hostname extraNixPath; })
        ++ (homeManagerModule {
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
  makeNixosWithHome = makeNixosWithHomeAndPkgs inputs.nixpkgs;
    
  # NixOS configuration with stable release
  makeStableNixosConfig = makeNixosSystemWithPkgs inputs.nixos-release;
  
  # NixOS configuration with stable release and home-manager
  makeStableNixosWithHome = makeNixosWithHomeAndPkgs inputs.nixos-release;
}
