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
      inherit (inputs);

      commonModule = [
        {
          nixpkgs.overlays = [
            inputs.self.overlay
            inputs.nur.overlay
          ];
        }
      ];

      waylandModule = [
        ({
          imports = [
            ./system/greetd.nix
            ./system/swaylock.nix
            ./system/xdg-portal.nix
          ];

          nixpkgs.overlays = [
            (
              self: super: {
                firefox = super.firefox.override { forceWayland = true; };
              }
            )
          ];
        })
      ];

      xorgModule = [
        ({
          imports = [
            ./system/autorandr.nix
            ./system/i3.nix
            ./system/xserver-hidpi.nix
            ./system/xserver.nix
          ];

          services = {
            xserver = {
              deviceSection = ''
                Option "TearFree" "true"
              '';
            };
          };

        })
      ];

    in
    {
      nixosConfigurations = {
        thinkpad = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules =
            commonModule ++
            # xorgModule ++
            waylandModule ++
            [
              { imports = [ ./hosts/thinkpad ./system ]; }

              inputs.home-manager.nixosModules.home-manager
              ({ config, system, ... }: {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.ivan =
                  ({ super, ... }: {
                    imports = [
                      ./home
                      ./home/sway.nix

                      # ./home/autorandr.nix
                      # ./home/i3.nix
                      # ./home/xsession.nix
                    ];

                    home.stateVersion = config.system.stateVersion;
                  });

                home-manager.extraSpecialArgs = {
                  inherit inputs system;
                  super = config;
                };
              })
            ];

          specialArgs = { inherit inputs; };
        };

        xps = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules =
            commonModule ++
            waylandModule ++
            [
              { imports = [ ./hosts/xps ./system ]; }

              inputs.home-manager.nixosModules.home-manager
              ({ config, system, ... }: {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.ivan =
                  ({ super, ... }: {
                    imports = [ ./home ];
                    home.stateVersion = config.system.stateVersion;
                  });

                home-manager.extraSpecialArgs = {
                  inherit inputs system;
                  super = config;
                };
              })
            ];

          specialArgs = { inherit inputs; };
        };
      };

      overlay = final: prev: { };

      packages.x86_64-linux = (builtins.head (builtins.attrValues inputs.self.nixosConfigurations)).pkgs;

      devShell.x86_64-linux = with inputs.self.packages.x86_64-linux;
        mkShell
          {
            buildInputs = [
            ];
          };
    };
}
