{
  description = "NixOS configuration";

  inputs = {
    # This is used to pin packages from master and unstable channels
    # respectively.
    nixpkgs-unstable-pin.url = "github:nixos/nixpkgs/nixos-unstable";

    # Release
    nixpkgs-23-05.url = "github:nixos/nixpkgs/nixos-23.05";
    home-manager-23-05 = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follows = "nixpkgs-23-05";
    };

    # Darwin
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-23-05";
    };

    nur.url = "github:nix-community/NUR";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, ... }@inputs:
    let
      makeNixosConfig = { nixpkgs, home-manager, hostname, system, modules, homeModules }:
        nixpkgs.lib.nixosSystem {
          inherit system;

          modules = [
            {
              imports = [ ./hosts/${hostname} ./system/nixos.nix ];
            }

            home-manager.nixosModules.home-manager
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

            inputs.home-manager-23-05.darwinModules.home-manager
            ({ config, system, ... }: {
              # Support legacy workflows that use `<nixpkgs>` etc.
              nix.nixPath.nixpkgs = "${inputs.nixpkgs-23-05}";

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
          nixpkgs = inputs.nixpkgs-23-05;
          home-manager = inputs.home-manager-23-05;
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
          nixpkgs = inputs.nixpkgs-23-05;
          home-manager = inputs.home-manager-23-05;
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
          nixpkgs = inputs.nixpkgs-23-05;
          home-manager = inputs.home-manager-23-05;
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
        nixpkgs-unstable-pin = import inputs.nixpkgs-unstable-pin { system = final.system; config = final.config; };
        helm-secrets = final.callPackage ./overlays/helm-secrets.nix { };
      };


    } // inputs.flake-utils.lib.eachDefaultSystem (system: {
      legacyPackages = import inputs.nixpkgs-23-05 ({ inherit system; });

      devShells = let pkgs = self.legacyPackages.${system}; in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              # Ansible project deps
              python310
              python310Packages.botocore
              python310Packages.boto3

              # Rust build
              openssl
              libiconv
              pkg-config
              cmake
              zlib
              darwin.Security
              darwin.apple_sdk.frameworks.SystemConfiguration
              cyrus_sasl
            ];
          };
        };
    })
  ;
}
