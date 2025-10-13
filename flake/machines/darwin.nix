{ inputs, ... }:
{
  "Ivans-MacBook-Pro" = inputs.nix-darwin-darwin-unstable.lib.darwinSystem {
    system = "aarch64-darwin";
    modules = [
      # Import machine-specific configuration
      ../../machines/Ivans-MacBook-Pro

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
              inputs.nixvim-any-unstable.homeModules.nixvim
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
              inputs.nixvim-any-unstable.homeModules.nixvim
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

  "Ivans-Mac-mini" = inputs.nix-darwin-darwin-release.lib.darwinSystem {
    system = "aarch64-darwin";
    modules = [
      # Import machine-specific configuration
      ../../machines/Ivans-Mac-mini

      # Basic system configuration
      {
        nixpkgs.overlays = [ inputs.self.overlay ];
        nixpkgs.config.allowUnfree = true;
        nix.nixPath = [
          "nixpkgs=${inputs.nixpkgs-darwin-release}"
          "nixpkgs-release=${inputs.nixpkgs-darwin-release}"
        ];
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

  "Lusha-Macbook-Ivan-Kovnatskyi" = inputs.nix-darwin-darwin-unstable.lib.darwinSystem {
    system = "aarch64-darwin";
    modules = [
      # Import machine-specific configuration
      ../../machines/Lusha-Macbook-Ivan-Kovnatskyi

      # Basic system configuration
      {
        nixpkgs.overlays = [ inputs.self.overlay ];
        nixpkgs.config.allowUnfree = true;
        nix.nixPath = [ "nixpkgs=${inputs.nixpkgs-darwin-unstable}" ];
        _module.args = {
          flake-inputs = inputs;
        };

        # System settings
        networking.hostName = "Lusha-Macbook-Ivan-Kovnatskyi";
        users.users."Ivan.Kovnatskyi".home = "/Users/Ivan.Kovnatskyi";
        system.stateVersion = 4;

        # Set primary user for nix-darwin features
        system.primaryUser = "Ivan.Kovnatskyi";
      }

      # Home Manager module
      inputs.home-manager-darwin-unstable.darwinModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          users."Ivan.Kovnatskyi" = {
            imports = [
              ../../machines/Lusha-Macbook-Ivan-Kovnatskyi/home
              inputs.nixvim-any-unstable.homeModules.nixvim
              {
                programs.home-manager.enable = true;
                home.username = "Ivan.Kovnatskyi";
                home.stateVersion = "24.05";
              }
            ];
          };
          extraSpecialArgs = {
            inherit inputs;
            system = "aarch64-darwin";
            username = "Ivan.Kovnatskyi";
          };
          sharedModules = [
            {
              # ```console
              # … while calling the 'derivationStrict' builtin
              #   at <nix/derivation-internal.nix>:34:12:
              #     33|
              #     34|   strict = derivationStrict drvAttrs;
              #       |            ^
              #     35|
              #
              # … while evaluating derivation 'darwin-system-25.05.4052178'
              #   whose name attribute is located at /nix/store/m4wcdchjxw2fdyzjp8i6irpc613pchkr-source/pkgs/stdenv/generic/make-derivation.nix:375:7
              #
              # … while evaluating attribute 'activationScript' of derivation 'darwin-system-25.05.4052178'
              #   at /nix/store/r7w65jwlv1m3sdw30cfzhadygb92krpi-source/modules/system/default.nix:97:7:
              #     96|
              #     97|       activationScript = cfg.activationScripts.script.text;
              #       |       ^
              #     98|       activationUserScript = cfg.activationScripts.userScript.text;
              #
              # … while evaluating the option `system.activationScripts.script.text':
              #
              # … while evaluating definitions from `/nix/store/r7w65jwlv1m3sdw30cfzhadygb92krpi-source/modules/system/activation-scripts.nix':
              #
              # … while evaluating the option `system.activationScripts.postActivation.text':
              #
              # … while evaluating definitions from `<unknown-file>':
              #
              # … while evaluating the option `home-manager.users."Ivan.Kovnatskyi".nix.package':
              #
              # … while evaluating definitions from `/nix/store/mldpn4s578783cshnqax2wzz8nnf1h7n-source/nixos/common.nix':
              #
              # … while evaluating the option `nix.package':
              #
              # (stack trace truncated; use '--show-trace' to show the full, detailed trace)
              #
              # error: nix.package: accessed when `nix.enable` is off; this is a bug in
              # nix-darwin or a third‐party module
              # waiting for changes
              # ```
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
            user = "Ivan.Kovnatskyi";
            autoMigrate = true;
            taps = {
              "homebrew/homebrew-core" = inputs.homebrew-core;
              "homebrew/homebrew-cask" = inputs.homebrew-cask;
              "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
              "pomdtr/homebrew-tap" = inputs.pomdtr-homebrew-tap;
            };
            mutableTaps = false;
          };
        }
      )
    ];
    specialArgs = {
      system = "aarch64-darwin";
      username = "Ivan.Kovnatskyi";
    };
  };
}
