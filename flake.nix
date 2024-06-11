{
  description = "NixOS configuration";

  inputs = {
    # This is used to pin packages from unstable channel.
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Release
    nixpkgs-release.url = "github:nixos/nixpkgs/nixos-24.05";
    home-manager-release = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs-release";
    };

    # Darwin
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-release";
    };

    # https://github.com/zhaofengli/nix-homebrew
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };

    nur.url = "github:nix-community/NUR";

    nixvim = {
      url = "github:nix-community/nixvim/nixos-24.05";
      inputs.nixpkgs.follows = "nixpkgs-release";
    };
  };

  outputs = { self, ... }@inputs:
    let
      makeNixosConfig = { nixpkgs, home-manager, hostname, system, modules, homeModules }:
        nixpkgs.lib.nixosSystem {
          inherit system;

          modules = [
            {
              imports = [ ./machines/${hostname} ./system/nixos.nix ];
            }

            home-manager.nixosModules.home-manager
            ({ config, system, ... }: {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.ivan = {
                imports = [
                  ./home
                  ./home/pass.nix
                  ./home/common.nix
                  ./home/nixos.nix

                  ./machines/${hostname}/home.nix
                ] ++ homeModules;
                home.stateVersion = config.system.stateVersion;
              };

              home-manager.extraSpecialArgs = {
                inherit inputs system;
                super = config;
              };
            })
          ] ++ modules;

          specialArgs = { inherit system; };
        };

      makeDarwinConfig = { hostname, system, modules, homeModules }:
        inputs.darwin.lib.darwinSystem {
          inherit system;

          modules = [
            {
              imports = [ ./machines/${hostname} ];
              nixpkgs.overlays = [ inputs.self.overlay ];
            }

            inputs.home-manager-release.darwinModules.home-manager
            ({ config, system, ... }: {
              # Support legacy workflows that use `<nixpkgs>` etc.
              nix.nixPath.nixpkgs = "${inputs.nixpkgs-release}";

              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.ivan = {
                imports = [
                  ./machines/${hostname}/home.nix
                  inputs.nixvim.homeManagerModules.nixvim
                ] ++ homeModules;
              };

              home-manager.extraSpecialArgs = {
                inherit inputs system;
                super = config;
              };
            })

          ] ++ modules;

          specialArgs = { inherit system; };
        };

    in
    {
      nixosConfigurations = { };

      darwinConfigurations = {
        "Ivans-MacBook-Pro" = makeDarwinConfig {
          hostname = "Ivans-MacBook-Pro";
          system = "aarch64-darwin";
          modules = [
            ({ config, ... }: {
              homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
            })
            inputs.nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                # Install Homebrew under the default prefix
                enable = true;

                # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
                enableRosetta = false;

                # User owning the Homebrew prefix
                user = "ivan";

                # Automatically migrate existing Homebrew installations
                autoMigrate = true;

                # Optional: Declarative tap management
                taps = {
                  "homebrew/homebrew-core" = inputs.homebrew-core;
                  "homebrew/homebrew-cask" = inputs.homebrew-cask;
                  "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
                };

                # Optional: Enable fully-declarative tap management
                #
                # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
                mutableTaps = false;
              };
            }
            ({
              nixpkgs.overlays = [
                (final: prev: {
                  nixpkgs-master = import inputs.nixpkgs-master { system = final.system; config = final.config; };
                })
              ];
            })
          ];
          homeModules = [
          ];
        };

        "Ivans-MacBook-Air" = makeDarwinConfig {
          hostname = "Ivans-MacBook-Air";
          system = "aarch64-darwin";
          modules = [
            ({ config, ... }: {
              homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
            })
            inputs.nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                # Install Homebrew under the default prefix
                enable = true;

                # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
                enableRosetta = false;

                # User owning the Homebrew prefix
                user = "ivan";

                # Automatically migrate existing Homebrew installations
                autoMigrate = true;

                # Optional: Declarative tap management
                taps = {
                  "homebrew/homebrew-core" = inputs.homebrew-core;
                  "homebrew/homebrew-cask" = inputs.homebrew-cask;
                  "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
                };

                # Optional: Enable fully-declarative tap management
                #
                # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
                mutableTaps = false;
              };
            }
            ({
              nixpkgs.overlays = [
                (final: prev: {
                  nixpkgs-master = import inputs.nixpkgs-master { system = final.system; config = final.config; };
                  nixpkgs-unstable = import inputs.nixpkgs-unstable { system = final.system; config = final.config; };
                })
              ];
            })
          ];
          homeModules = [
            ./home/pass.nix
          ];
        };
      };

      overlay = final: prev: { };
    };
}
