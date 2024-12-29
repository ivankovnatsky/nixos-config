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
          ];
          homeModules = [
          ];
        };

        "Ivans-MacBook-Air" = makeDarwinConfig {
          hostname = "Ivans-MacBook-Air";
          system = "aarch64-darwin";
          username = "ivan";
          modules = [
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
          ];
          homeModules = [
          ];
        };
      };

      overlay = final: prev:
        let
          # 1. Automatic overlays from overlays/ directory
          overlayDirs = builtins.readDir ./overlays;
          overlayList = builtins.mapAttrs (name: type: { inherit name type; }) overlayDirs;
          autoOverlays = builtins.foldl'
            (acc: dir: acc // {
              ${dir.name} = prev.callPackage (./overlays + "/${dir.name}") { };
            })
            { }
            (builtins.filter (dir: dir.type == "directory") (builtins.attrValues overlayList));

          # 2. Nixpkgs-master packages
          masterOverlays = {
            nixpkgs-master = import inputs.nixpkgs-master {
              inherit (final) system config;
            };
          };

          # 3. Direct packages from other flakes
          flakeOverlays = {
            username = inputs.username.packages.${final.system}.username;
          };
        in
        # Merge all overlay types
        autoOverlays // masterOverlays // flakeOverlays;
    };
}
