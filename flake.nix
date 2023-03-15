{
  description = "NixOS configuration";

  inputs = {
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Linux
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nur.url = "github:nix-community/NUR";

    # Mac
    nixpkgs-mac.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager-mac.url = "github:nix-community/home-manager";
    home-manager-mac.inputs.nixpkgs.follows = "nixpkgs-mac";

    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs-mac";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, ... }@inputs:
    let
      makeNixosConfig = { hostname, system, modules, homeModules }:
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;

          modules = [
            {
              imports = [ ./hosts/${hostname} ./system/nixos.nix ];
            }

            inputs.home-manager.nixosModules.home-manager
            ({ config, system, ... }: {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.ivan = {
                imports = [
                  ./home
                  ./home/common.nix
                  ./home/nixos.nix

                  ./hosts/${hostname}/home.nix
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
              imports = [ ./hosts/${hostname} ];
              nixpkgs.overlays = [ inputs.self.overlay ];
            }

            inputs.home-manager-mac.darwinModules.home-manager
            ({ config, system, ... }: {
              # Support legacy workflows that use `<nixpkgs>` etc.
              nix.nixPath.nixpkgs = "${inputs.nixpkgs-mac}";

              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.ivan = {
                imports = [
                  ./home
                  ./home/common.nix
                  ./home/hammerspoon
                  ./home/darwin.nix

                  ./hosts/${hostname}/home.nix
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
      nixosConfigurations = {
        desktop = makeNixosConfig {
          hostname = "desktop";
          system = "x86_64-linux";

          modules = [
            ./system
            ./system/workstation.nix
            ./system/greetd.nix
            ./system/swaylock.nix

            {
              nixpkgs.overlays = [ inputs.self.overlay inputs.nur.overlay ];
            }
          ];

          homeModules = [
            ./home/common.nix
            ./home/nixos-workstation.nix
            ./home/sway.nix
          ];
        };

        ax41 = makeNixosConfig {
          hostname = "ax41";
          system = "x86_64-linux";

          modules = [
            ./system

            {
              nixpkgs.overlays = [ inputs.self.overlay ];
            }
          ];

          homeModules = [ ];
        };

        ax41-ikovnatsky = makeNixosConfig {
          hostname = "ax41-ikovnatsky";
          system = "x86_64-linux";

          modules = [
            ./system

            {
              nixpkgs.overlays = [ inputs.self.overlay ];
            }
          ];

          homeModules = [ ];
        };
      };

      darwinConfigurations = {
        "Ivans-MacBook-Pro" = makeDarwinConfig {
          hostname = "Ivans-MacBook-Pro";
          system = "aarch64-darwin";
          modules = [ ];
          homeModules = [ ];
        };
      };

      overlay = final: prev: {
        nixpkgs-unstable = import inputs.nixpkgs-unstable { system = final.system; config = final.config; };
        helm-secrets = final.callPackage ./overlays/helm-secrets.nix { };
        iam-policy-json-to-terraform = final.callPackage ./overlays/iam-policy-json-to-terraform.nix { };
      };


    } // inputs.flake-utils.lib.eachDefaultSystem (system: {
      legacyPackages = import inputs.nixpkgs ({ inherit system; });

      devShells = let pkgs = self.legacyPackages.${system}; in
        {
          default = pkgs.mkShell { };
        };
    })
  ;
}
