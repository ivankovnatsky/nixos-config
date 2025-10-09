{ inputs, ... }:
{
  "bee" = inputs.nixos-release.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      # Import machine-specific configuration
      ../../machines/bee

      # Basic system configuration
      {
        nixpkgs.overlays = [ inputs.self.overlay ];
        nixpkgs.config.allowUnfree = true;
        nix.nixPath = [
          "nixpkgs=${inputs.nixos-release}"
          "nixos-release=${inputs.nixos-release}"
        ];
        _module.args = {
          flake-inputs = inputs;
        };

        # System settings
        networking.hostName = "bee";
        users.users.ivan.home = "/home/ivan";
        system.stateVersion = "24.11";
      }
    ];
    specialArgs = {
      system = "x86_64-linux";
      username = "ivan";
    };
  };

  "a3" = inputs.nixos-release.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      # Import machine-specific configuration
      ../../machines/a3

      # Basic system configuration
      {
        nixpkgs.overlays = [
          inputs.self.overlay
          inputs.nur.overlay
        ];
        nixpkgs.config.allowUnfree = true;
        nix.nixPath = [
          "nixpkgs=${inputs.nixos-release}"
          "nixos-release=${inputs.nixos-release}"
        ];
        _module.args = {
          flake-inputs = inputs;
        };

        # System settings
        networking.hostName = "a3";
        users.users.ivan.home = "/home/ivan";
      }

      # Home Manager module
      inputs.home-manager-nixos-release.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.ivan = {
            imports = [
              ../../machines/a3/home
              inputs.nixvim-release-nixos.homeManagerModules.nixvim
              inputs.plasma-manager-release.homeManagerModules.plasma-manager
            ];
          };
          extraSpecialArgs = {
            inherit inputs;
            system = "x86_64-linux";
            username = "ivan";
          };
          sharedModules = [
            {
              home.stateVersion = "25.05";
            }
          ];
        };
      }
    ];
    specialArgs = {
      system = "x86_64-linux";
      username = "ivan";
    };
  };

  "mini-vm" = inputs.nixos-release.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [
      # Import machine-specific configuration
      ../../machines/mini-vm

      # Basic system configuration
      {
        nixpkgs.overlays = [ inputs.self.overlay ];
        nixpkgs.config.allowUnfree = true;
        nix.nixPath = [
          "nixpkgs=${inputs.nixos-release}"
          "nixos-release=${inputs.nixos-release}"
        ];
        _module.args = {
          flake-inputs = inputs;
        };

        # System settings
        networking.hostName = "mini-vm";
        users.users.ivan.home = "/home/ivan";
        system.stateVersion = "25.05";
      }

      # Home Manager module
      inputs.home-manager-nixos-release.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          users.ivan = {
            imports = [
              ../../machines/mini-vm/home
            ];
          };
          extraSpecialArgs = {
            inherit inputs;
            system = "aarch64-linux";
            username = "ivan";
          };
          sharedModules = [
            {
              home.stateVersion = "25.05";
            }
          ];
        };
      }
    ];
    specialArgs = {
      system = "aarch64-linux";
      username = "ivan";
    };
  };
}
