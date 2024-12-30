{ inputs, ... }:
let
  makeDarwinConfig = { hostname, system, modules, homeModules, username }:
    inputs.darwin.lib.darwinSystem {
      inherit system;

      modules = [
        {
          imports = [ ../machines/${hostname} ];
          nixpkgs.overlays = [ inputs.self.overlay ];
        }

        inputs.home-manager.darwinModules.home-manager
        ({ config, system, ... }: {
          nix.nixPath.nixpkgs = "${inputs.nixpkgs}";

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${username} = {
              imports = [
                ../machines/${hostname}/home.nix
                inputs.nixvim.homeManagerModules.nixvim
              ] ++ homeModules;
            };

            extraSpecialArgs = {
              inherit inputs system username;
              super = config;
            };
          };
        })

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
      ] ++ modules;

      specialArgs = { inherit system username; };
    };
in
{
  darwinConfigurations = {
    "Ivans-MacBook-Pro" = makeDarwinConfig {
      hostname = "Ivans-MacBook-Pro";
      system = "aarch64-darwin";
      username = "ivan";
      modules = [ ];
      homeModules = [ ];
    };

    "Ivans-MacBook-Air" = makeDarwinConfig {
      hostname = "Ivans-MacBook-Air";
      system = "aarch64-darwin";
      username = "ivan";
      modules = [ ];
      homeModules = [ ../home/pass.nix ];
    };

    "Lusha-Macbook-Ivan-Kovnatskyi" = makeDarwinConfig {
      hostname = "Lusha-Macbook-Ivan-Kovnatskyi";
      system = "aarch64-darwin";
      username = "Ivan.Kovnatskyi";
      modules = [ ];
      homeModules = [ ];
    };
  };
}
