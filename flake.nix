{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    nur.url = "github:nix-community/NUR";
  };

  outputs = inputs:
    let
      editorName = "nvim";

      commonModule = [
        ({ pkgs, ... }: {
          environment = {
            variables = {
              EDITOR = editorName;
              VISUAL = editorName;
            };
          };

          nixpkgs.config.allowUnfree = true;

          nix = {
            package = pkgs.nixUnstable;
            extraOptions = ''
              experimental-features = nix-command flakes
            '';
          };
        })
      ];

      darwinModule = [
        ({ pkgs, ... }: {
          environment.systemPackages = with pkgs; [
            gnupg
          ];
        })
      ];

    in
    {
      nixosConfigurations = {
        thinkpad = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules = commonModule ++ [
            ./hosts/thinkpad

            {
              nixpkgs.overlays = [ inputs.nur.overlay ];
              nix.autoOptimiseStore = true;
            }

            inputs.home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.ivan = import ./hosts/thinkpad/home.nix;
            }
          ];
        };
      };

      darwinConfigurations = {
        "Ivans-MacBook-Pro" = inputs.darwin.lib.darwinSystem {
          modules =
            commonModule ++
            darwinModule ++
            [
              ./hosts/macbook

              inputs.home-manager.darwinModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.ivan = import ./hosts/macbook/home.nix;
              }
            ];
        };

        "workbook" = inputs.darwin.lib.darwinSystem {
          modules =
            commonModule ++
            darwinModule ++
            [
              ./hosts/workbook

              inputs.home-manager.darwinModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.ivan = import ./hosts/workbook/home.nix;
              }
            ];
        };
      };

      packages.x86_64-linux = (builtins.head (builtins.attrValues inputs.self.nixosConfigurations)).pkgs;

      devShell.x86_64-linux = with inputs.self.packages.x86_64-linux;
        mkShell {
          buildInputs = [
          ];
        };

    };
}
