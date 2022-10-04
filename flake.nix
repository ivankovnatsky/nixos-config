{
  description = "NixOS configuration";

  inputs = {
    # Linux
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Mac
    nixpkgs-mac.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager-mac.url = "github:nix-community/home-manager";
    home-manager-mac.inputs.nixpkgs.follows = "nixpkgs-mac";
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs-mac";

    nur.url = "github:nix-community/NUR";
  };

  outputs = inputs:
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
            ./home/workstation.nix
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
        helm-secrets = final.callPackage ./overlays/helm-secrets.nix { };
        iam-policy-json-to-terraform = final.callPackage ./overlays/iam-policy-json-to-terraform.nix { };
      };

      packages.x86_64-linux = (builtins.head (builtins.attrValues inputs.self.nixosConfigurations)).pkgs;

      devShell.x86_64-linux = with inputs.self.packages.x86_64-linux;
        mkShell
          {
            buildInputs = [
            ];
          };
    };
}
