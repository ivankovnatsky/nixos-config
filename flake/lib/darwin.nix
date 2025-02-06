{ inputs, ... }:
let
  inherit (import ./system.nix { inherit inputs; }) baseModule;
  inherit (import ./home.nix { inherit inputs; }) homeManagerModule;

  # Darwin-specific homebrew configuration
  darwinHomebrewModule = { username }: [
    ({ config, ... }: {
      homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
    })
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
in
{
  inherit darwinHomebrewModule;

  # Base Darwin system configuration without home-manager
  makeBaseDarwinSystem = { hostname, system, username }:
    inputs.darwin.lib.darwinSystem {
      inherit system;
      modules = baseModule { inherit hostname; };
    };

  # Darwin configuration with home-manager but without nixvim
  makeBaseDarwinWithHome = { hostname, system, username }:
    inputs.darwin.lib.darwinSystem {
      inherit system;
      modules =
        baseModule { inherit hostname; } ++
        homeManagerModule { inherit hostname username; };
    };

  # Full featured Darwin configuration with home-manager and nixvim
  makeFullDarwinConfig = { hostname, system, username, modules ? [ ], homeModules ? [ ] }:
    inputs.darwin.lib.darwinSystem {
      inherit system;
      modules =
        baseModule { inherit hostname; } ++
        homeManagerModule {
          inherit hostname username;
          extraImports = [ inputs.nixvim.homeManagerModules.nixvim ] ++ homeModules;
        } ++
        darwinHomebrewModule { inherit username; } ++
        modules;

      specialArgs = { inherit system username; };
    };
}
