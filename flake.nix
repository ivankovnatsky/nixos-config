{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nur.url = "github:nix-community/NUR";
  };

  outputs = inputs:
    let
      makeNixosConfig = { hostname ? "thinkpad", system ? "x86_64-linux" }:
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;

          modules = [
            {
              imports = [ ./hosts/${hostname} ./system ./system/wayland.nix ];
              nixpkgs.overlays = [ inputs.self.overlay inputs.nur.overlay ];
            }

            inputs.home-manager.nixosModules.home-manager
            ({ config, system, ... }: {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.ivan = {
                imports = [ ./home ./home/sway.nix ];
                home.stateVersion = config.system.stateVersion;
              };

              home-manager.extraSpecialArgs = {
                inherit inputs system;
                super = config;
              };
            })
          ];

          specialArgs = { inherit inputs; };
        };

    in
    {
      nixosConfigurations = {
        thinkpad = makeNixosConfig { };

        xps = makeNixosConfig {
          hostname = "xps";
        };
      };

      overlay = final: prev: {
        helm-secrets = final.callPackage ./overlays/helm-secrets.nix { };
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
