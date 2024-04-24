{
  description = "NixOS configuration";

  inputs = {
    # This is used to pin packages from unstable channel.
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Release
    nixpkgs-23-11.url = "github:nixos/nixpkgs/nixos-23.11";
    home-manager-23-11 = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs-23-11";
    };

    # Darwin
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-23-11";
    };

    nur.url = "github:nix-community/NUR";

    nixvim = {
      url = "github:nix-community/nixvim/nixos-23.11";
      inputs.nixpkgs.follows = "nixpkgs-23-11";
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

            inputs.home-manager-23-11.darwinModules.home-manager
            ({ config, system, ... }: {
              # Support legacy workflows that use `<nixpkgs>` etc.
              nix.nixPath.nixpkgs = "${inputs.nixpkgs-23-11}";

              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.ivan = {
                imports = [
                  ./machines/${hostname}/home.nix
                  inputs.nixvim.homeManagerModules.nixvim
                ] ++ homeModules;

                home.stateVersion = "22.05";
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
                  nixpkgs-unstable = import inputs.nixpkgs-unstable { system = final.system; config = final.config; };
                })
              ];
            })
          ];
          homeModules = [
            ./home
            ./home/pass.nix
            ./home/common.nix
            ./home/hammerspoon
            ./home/darwin.nix
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
