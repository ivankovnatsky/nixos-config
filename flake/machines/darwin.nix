# home.stateVersion policy:
#   Each machine pins its own home.stateVersion to whatever was current when
#   the user profile was first activated on that host, and is intentionally
#   never bumped. Drift across hosts (23.11, 22.05, 25.05, 24.05) is expected
#   — bumping a value here is a manual decision per host, not a copy/paste
#   side effect. When templating a new machine block from an existing one,
#   set home.stateVersion to the home-manager release current at host first
#   activation rather than inheriting the source machine's value.
{ inputs, ... }:
{
  "Ivans-MacBook-Pro" = inputs.nix-darwin-darwin-unstable.lib.darwinSystem {
    system = "aarch64-darwin";
    modules = [
      # Import machine-specific configuration
      ../../machines/Ivans-MacBook-Pro

      # SOPS secrets management
      inputs.sops-nix-darwin-unstable.darwinModules.sops
      ../../secrets/sops-nix.nix

      # Basic system configuration
      {
        nixpkgs.overlays = [ inputs.self.overlay ];
        nixpkgs.config.allowUnfree = true;
        nix.nixPath = [ "nixpkgs=${inputs.nixpkgs-darwin-unstable}" ];
        _module.args = {
          flake-inputs = inputs;
        };

        # System settings
        networking.hostName = "Ivans-MacBook-Pro";
        users.users.ivan.home = "/Users/ivan";
        system.stateVersion = 4;

        # Set primary user for nix-darwin features
        system.primaryUser = "ivan";
      }

      # Home Manager module
      inputs.home-manager-darwin-unstable.darwinModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          users.ivan = {
            imports = [
              ../../machines/Ivans-MacBook-Pro/home
              inputs.nixvim-darwin-unstable.homeModules.nixvim
              inputs.sops-nix-darwin-unstable.homeManagerModules.sops
              {
                programs.home-manager.enable = true;
                home.username = "ivan";
                home.stateVersion = "23.11";
              }
            ];
          };
          extraSpecialArgs = {
            inherit inputs;
            system = "aarch64-darwin";
            username = "ivan";
          };
          sharedModules = [
            {
              # Prevent nix.package error in home-manager
              nix.enable = false;
            }
          ];
        };
      }

      # Homebrew module
      inputs.nix-homebrew.darwinModules.nix-homebrew
      (
        { config, ... }:
        {
          homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            user = "ivan";
            autoMigrate = true;
            taps = {
              "homebrew/homebrew-core" = inputs.homebrew-core;
              "homebrew/homebrew-cask" = inputs.homebrew-cask;
              "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
              "pomdtr/homebrew-tap" = inputs.pomdtr-homebrew-tap;
              "keith/homebrew-formulae" = inputs.keith-homebrew-tap;
              "antoniorodr/homebrew-memo" = inputs.antoniorodr-homebrew-tap;
              "xwmx/homebrew-taps" = inputs.xwmx-homebrew-tap;
            };
            mutableTaps = false;
          };
        }
      )
    ];
    specialArgs = {
      system = "aarch64-darwin";
      username = "ivan";
    };
  };

  "Ivans-MacBook-Air" = inputs.nix-darwin-darwin-unstable.lib.darwinSystem {
    system = "aarch64-darwin";
    modules = [
      # Import machine-specific configuration
      ../../machines/Ivans-MacBook-Air

      # SOPS secrets management
      inputs.sops-nix-darwin-unstable.darwinModules.sops
      ../../secrets/sops-nix.nix

      # Basic system configuration
      {
        nixpkgs.overlays = [ inputs.self.overlay ];
        nixpkgs.config.allowUnfree = true;
        nix.nixPath = [ "nixpkgs=${inputs.nixpkgs-darwin-unstable}" ];
        _module.args = {
          flake-inputs = inputs;
        };

        # System settings
        networking.hostName = "Ivans-MacBook-Air";
        users.users.ivan.home = "/Users/ivan";
        system.stateVersion = 4;

        # Set primary user for nix-darwin features
        system.primaryUser = "ivan";
      }

      # Home Manager module
      inputs.home-manager-darwin-unstable.darwinModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          users.ivan = {
            imports = [
              ../../machines/Ivans-MacBook-Air/home
              inputs.nixvim-darwin-unstable.homeModules.nixvim
              inputs.sops-nix-darwin-unstable.homeManagerModules.sops
              {
                programs.home-manager.enable = true;
                home.username = "ivan";
                home.stateVersion = "22.05";
              }
            ];
          };
          extraSpecialArgs = {
            inherit inputs;
            system = "aarch64-darwin";
            username = "ivan";
          };
          sharedModules = [
            {
              # Prevent nix.package error in home-manager
              nix.enable = false;
            }
          ];
        };
      }

      # Homebrew module
      inputs.nix-homebrew.darwinModules.nix-homebrew
      (
        { config, ... }:
        {
          homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            user = "ivan";
            autoMigrate = true;
            taps = {
              "homebrew/homebrew-core" = inputs.homebrew-core;
              "homebrew/homebrew-cask" = inputs.homebrew-cask;
              "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
              "pomdtr/homebrew-tap" = inputs.pomdtr-homebrew-tap;
              "keith/homebrew-formulae" = inputs.keith-homebrew-tap;
              "antoniorodr/homebrew-memo" = inputs.antoniorodr-homebrew-tap;
              "xwmx/homebrew-taps" = inputs.xwmx-homebrew-tap;
            };
            mutableTaps = false;
          };
        }
      )
    ];
    specialArgs = {
      system = "aarch64-darwin";
      username = "ivan";
    };
  };

  "Ivans-Mac-mini" = inputs.nix-darwin-darwin-unstable.lib.darwinSystem {
    system = "aarch64-darwin";
    modules = [
      # Import machine-specific configuration
      ../../machines/Ivans-Mac-mini

      # SOPS secrets management
      inputs.sops-nix-darwin-unstable.darwinModules.sops
      ../../secrets/sops-nix.nix

      # Basic system configuration
      {
        nixpkgs.overlays = [ inputs.self.overlay ];
        nixpkgs.config.allowUnfree = true;
        nix.nixPath = [ "nixpkgs=${inputs.nixpkgs-darwin-unstable}" ];
        _module.args = {
          flake-inputs = inputs;
        };

        # System settings
        networking.hostName = "Ivans-Mac-mini";
        users.users.ivan.home = "/Users/ivan";
        system.stateVersion = 5;

        system.primaryUser = "ivan";
      }

      # Homebrew module
      inputs.nix-homebrew.darwinModules.nix-homebrew
      (
        { config, ... }:
        {
          homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            user = "ivan";
            autoMigrate = true;
            taps = {
              "homebrew/homebrew-core" = inputs.homebrew-core;
              "homebrew/homebrew-cask" = inputs.homebrew-cask;
              "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
              "pomdtr/homebrew-tap" = inputs.pomdtr-homebrew-tap;
              "keith/homebrew-formulae" = inputs.keith-homebrew-tap;
              "antoniorodr/homebrew-memo" = inputs.antoniorodr-homebrew-tap;
              "xwmx/homebrew-taps" = inputs.xwmx-homebrew-tap;
            };
            mutableTaps = false;
          };
        }
      )

      # Home Manager module
      inputs.home-manager-darwin-unstable.darwinModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          users.ivan = {
            imports = [
              ../../machines/Ivans-Mac-mini/home
              inputs.nixvim-darwin-unstable.homeModules.nixvim
              inputs.sops-nix-darwin-unstable.homeManagerModules.sops
              {
                programs.home-manager.enable = true;
                home.username = "ivan";
                home.stateVersion = "25.05";
              }
            ];
          };
          extraSpecialArgs = {
            inherit inputs;
            system = "aarch64-darwin";
            username = "ivan";
          };
          sharedModules = [
            {
              # Prevent nix.package error in home-manager
              nix.enable = false;
            }
          ];
        };
      }
    ];
    specialArgs = {
      system = "aarch64-darwin";
      username = "ivan";
    };
  };
}
