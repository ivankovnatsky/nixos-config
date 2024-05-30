{
  description = "NixOS configuration";

  inputs = {
    # This is used to pin packages from unstable channel.
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Release
    nixpkgs-release.url = "github:nixos/nixpkgs/nixos-23.11";
    home-manager-release = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs-release";
    };

    # Darwin
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-release";
    };

    nur.url = "github:nix-community/NUR";

    nixvim = {
      url = "github:nix-community/nixvim/nixos-23.11";
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
