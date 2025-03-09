{ inputs, ... }:
let
  inherit (import ./system.nix { inherit inputs; }) systemModule;
  inherit (import ./home.nix { inherit inputs; }) darwinHomeManagerModule stableDarwinHomeManagerModule;

  # Darwin-specific homebrew configuration
  darwinHomebrewModule =
    { username }:
    [
      (
        { config, ... }:
        {
          homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
        }
      )
      inputs.nix-homebrew.darwinModules.nix-homebrew
      {
        nix-homebrew = {
          enable = true;
          enableRosetta = false;
          user = username;
          autoMigrate = true;
          taps = {
            "homebrew/homebrew-core" = inputs.homebrew-core;
            "homebrew/homebrew-cask" = inputs.homebrew-cask;
            "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
          };
          mutableTaps = false;
        };
      }
    ];

  # Helper function to create a basic Darwin system with a specific darwin input
  makeBaseDarwinSystemWithInputs =
    darwinInput:
    {
      hostname,
      system,
      username,
      modules ? [ ],
      extraNixPath ? { },
    }:
    darwinInput.lib.darwinSystem {
      inherit system;
      modules = (systemModule { 
        inherit hostname extraNixPath; 
        nixpkgsInput = if darwinInput == inputs.darwin-release then inputs.nixpkgs-release else inputs.nixpkgs;
        nixpkgsReleaseInput = if darwinInput == inputs.darwin-release then inputs.nixpkgs-release else null;
      }) ++ modules;
      specialArgs = { inherit system username; };
    };

  # Helper function to create a Darwin system with home-manager and specific inputs
  makeBaseDarwinWithHomeAndInputs =
    darwinInput: homeManagerInput: hmModule:
    {
      hostname,
      system,
      username,
      modules ? [ ],
      homeModules ? [ ],
      extraNixPath ? { },
    }:
    darwinInput.lib.darwinSystem {
      inherit system;
      modules = 
        (systemModule { 
          inherit hostname extraNixPath; 
          nixpkgsInput = if darwinInput == inputs.darwin-release then inputs.nixpkgs-release else inputs.nixpkgs;
          nixpkgsReleaseInput = if darwinInput == inputs.darwin-release then inputs.nixpkgs-release else null;
        }) 
        ++ (hmModule { 
          inherit hostname username; 
          extraImports = homeModules;
        })
        ++ modules;
      specialArgs = { inherit system username; };
    };

  # Helper function to create a full featured Darwin system with specific inputs
  makeFullDarwinConfigWithInputs =
    darwinInput: homeManagerInput: hmModule:
    {
      hostname,
      system,
      username,
      modules ? [ ],
      homeModules ? [ ],
      extraNixPath ? { },
    }:
    darwinInput.lib.darwinSystem {
      inherit system;
      modules =
        (systemModule { 
          inherit hostname extraNixPath; 
          nixpkgsInput = if darwinInput == inputs.darwin-release then inputs.nixpkgs-release else inputs.nixpkgs;
          nixpkgsReleaseInput = if darwinInput == inputs.darwin-release then inputs.nixpkgs-release else null;
        })
        ++ (hmModule {
          inherit hostname username;
          extraImports = [ inputs.nixvim.homeManagerModules.nixvim ] ++ homeModules;
        })
        ++ (darwinHomebrewModule { inherit username; })
        ++ modules;

      specialArgs = { inherit system username; };
    };
in
{
  inherit darwinHomebrewModule;

  # Darwin configuration with unstable channel (default)
  makeBaseDarwinSystem = makeBaseDarwinSystemWithInputs inputs.darwin;
  makeBaseDarwinWithHome = makeBaseDarwinWithHomeAndInputs inputs.darwin inputs.home-manager darwinHomeManagerModule;
  makeFullDarwinConfig = makeFullDarwinConfigWithInputs inputs.darwin inputs.home-manager darwinHomeManagerModule;
  
  # Darwin configuration with stable release
  makeStableBaseDarwinSystem = makeBaseDarwinSystemWithInputs inputs.darwin-release;
  makeStableBaseDarwinWithHome = makeBaseDarwinWithHomeAndInputs inputs.darwin-release inputs.home-manager-release stableDarwinHomeManagerModule;
  makeStableFullDarwinConfig = makeFullDarwinConfigWithInputs inputs.darwin-release inputs.home-manager-release stableDarwinHomeManagerModule;
}
