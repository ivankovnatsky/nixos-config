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
      makeNixosConfig = { hostname ? "xps", system ? "x86_64-linux", modules, homeModules }:
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;

          modules = [
            {
              imports = [ ./hosts/${hostname} ./system ];
              nixpkgs.overlays = [ inputs.self.overlay inputs.nur.overlay ];
            }

            inputs.home-manager.nixosModules.home-manager
            ({ config, system, ... }: {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.ivan = {
                imports = [ ./home ] ++ homeModules;
                home.stateVersion = config.system.stateVersion;
              };

              home-manager.extraSpecialArgs = {
                inherit inputs system;
                super = config;
              };
            })
          ] ++ modules;

          specialArgs = { inherit inputs; };
        };

    in
    {
      nixosConfigurations = {
        xps = makeNixosConfig {
          modules = [
            ./system/wayland.nix
          ];

          homeModules = [ ./home/sway.nix ];
        };

        thinkpad = makeNixosConfig {
          hostname = "thinkpad";
          modules = [
            ./system/wayland.nix
          ];

          homeModules = [ ./home/sway.nix ];
        };
      };

      overlay = final: prev: {
        helm-secrets = final.callPackage ./overlays/helm-secrets.nix { };
        bloomrpc = final.callPackage ./overlays/bloomrpc.nix { };
        rbw = final.callPackage ./overlays/rbw.nix {
          withFzf = true;
          inherit (inputs.nixpkgs.pkgs.darwin.apple_sdk.frameworks) Security;
        };
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
