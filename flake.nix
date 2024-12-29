{
  description = "NixOS configuration";

  inputs = {
    # This is used to pin packages from master channel.
    nixpkgs-master.url = "github:nixos/nixpkgs/master";

    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Darwin
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
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
      url = "github:nix-community/nixvim/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

    username = {
      url = "github:ivankovnatsky/username";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, ... }@inputs:
    let
      makeDarwinConfig = { hostname, system, modules, homeModules, username }:
        inputs.darwin.lib.darwinSystem {
          inherit system;

          modules = [
            {
              imports = [ ./machines/${hostname} ];
              nixpkgs.overlays = [ inputs.self.overlay ];
            }

            inputs.home-manager.darwinModules.home-manager
            ({ config, system, ... }: {
              # Support legacy workflows that use `<nixpkgs>` etc.
              nix.nixPath.nixpkgs = "${inputs.nixpkgs}";

              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.${username} = {
                  imports = [
                    ./machines/${hostname}/home.nix
                    inputs.nixvim.homeManagerModules.nixvim
                  ] ++ homeModules;
                };

                extraSpecialArgs = {
                  inherit inputs system;
                  super = config;
                };
              };
            })

          ] ++ modules;

          specialArgs = { inherit system; };
        };

    in
    {
      darwinConfigurations = {
        "Ivans-MacBook-Pro" = makeDarwinConfig {
          hostname = "Ivans-MacBook-Pro";
          system = "aarch64-darwin";
          username = "ivan";
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
            {
              nixpkgs.overlays = [
                (final: prev: {
                  nixpkgs-master = import inputs.nixpkgs-master {
                    inherit (final) system config;
                  };
                })
              ];
            }
          ];
          homeModules = [
          ];
        };

        "Ivans-MacBook-Air" = makeDarwinConfig {
          hostname = "Ivans-MacBook-Air";
          system = "aarch64-darwin";
          username = "ivan";
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
            {
              nixpkgs.overlays = [
                (final: prev: {
                  username = inputs.username.packages.${final.system}.username;
                  nixpkgs-master = import inputs.nixpkgs-master {
                    inherit (final) system config;
                  };
                })
              ];
            }
          ];
          homeModules = [
            ./home/pass.nix
          ];
        };

        "Lusha-Macbook-Ivan-Kovnatskyi" = makeDarwinConfig {
          hostname = "Lusha-Macbook-Ivan-Kovnatskyi";
          system = "aarch64-darwin";
          username = "Ivan.Kovnatskyi";
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
                user = "Ivan.Kovnatskyi";

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
            {
              nixpkgs.overlays = [
                (final: prev: {
                  nixpkgs-master = import inputs.nixpkgs-master {
                    inherit (final) system config;
                  };
                })
              ];
            }
          ];
          homeModules = [
          ];
        };
      };

      overlay = final: prev: {
        battery-toolkit = prev.callPackage ./overlays/battery-toolkit.nix { };
        coconutbattery = prev.callPackage ./overlays/coconutbattery.nix { };
        gh-token = prev.callPackage ./overlays/gh-token.nix { };
        ghostty = prev.callPackage ./overlays/ghostty { };
        ks = prev.callPackage ./overlays/ks.nix { };
        terragrunt-atlantis-config = prev.callPackage ./overlays/terragrunt-atlantis-config.nix { };
        watchman-make = prev.callPackage ./overlays/watchman-make.nix { };
      };
    };
}
